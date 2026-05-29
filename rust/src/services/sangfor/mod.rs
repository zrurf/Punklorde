//! Sangfor SSL VPN Service
//!
//! Manages the VPN connection: authentication, TUN device creation,
//! and bidirectional data relay between the TUN interface and the Go tunnel.

pub mod ffi;
pub mod constants;

use std::net::Ipv4Addr;
use std::ffi::{c_int, c_void};
#[cfg(target_os = "android")]
use std::os::fd::AsRawFd;
use std::panic::{self, AssertUnwindSafe};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use tracing::{error, info};

use crate::frb_generated::StreamSink;
use self::ffi::GoVpnClient;

/// VPN 连接状态
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[frb]
pub enum VpnState {
    Disconnected,
    Connecting,
    LoginStart,
    LoginPassword,
    WaitingSms,
    WaitingTotp,
    GettingToken,
    GettingResources,
    GettingIp,
    OpeningChannels,
    Connected,
    Error,
}

/// VPN 配置
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct VpnConfig {
    pub server: String,
    pub username: String,
    pub password: String,
    pub totp_secret: String,
    /// 自定义 DNS 服务器（可选，不填则使用 VPN 分配的）
    pub custom_dns: Option<String>,
    /// TUN 设备名称（可选）
    pub tun_name: Option<String>,
    /// TUN 设备 IP 地址
    pub tun_address: String,
    /// TUN 设备子网掩码
    pub tun_netmask: String,
    /// MTU
    pub mtu: u16,
    /// 分流路由（CIDR 列表，逗号分隔，如 "10.0.0.0/8,192.168.0.0/16"）
    /// 为空则默认路由所有流量走 VPN
    pub split_routes: Option<String>,
}

impl Default for VpnConfig {
    fn default() -> Self {
        Self {
            server: String::new(),
            username: String::new(),
            password: String::new(),
            totp_secret: String::new(),
            custom_dns: None,
            tun_name: None,
            tun_address: "10.0.0.2".to_string(),
            tun_netmask: "255.255.255.0".to_string(),
            mtu: 1500,
            split_routes: Some("10.0.0.0/8,172.16.0.0/12,192.168.0.0/16".to_string()),
        }
    }
}

/// VPN traffic statistics
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[frb]
pub struct VpnTrafficStats {
    pub bytes_sent: u64,
    pub bytes_received: u64,
    pub packets_sent: u64,
    pub packets_received: u64,
}

/// Sangfor SSL VPN 服务 —— 作为 opaque handler 传给 Flutter
pub struct SangforVpnService {
    config: Arc<Mutex<VpnConfig>>,
    state: Arc<Mutex<VpnState>>,
    running: Arc<AtomicBool>,
    client: Arc<Mutex<Option<GoVpnClient>>>,
    stream_sink: Arc<Mutex<Option<StreamSink<VpnState>>>>,
    last_error: Arc<Mutex<Option<String>>>,
    /// Android: fd from VpnService.Builder.establish(). Set via set_tun_fd().
    tun_fd: Arc<Mutex<Option<i32>>>,
    /// Traffic stats
    traffic: Arc<TrafficCounters>,
    /// Server-assigned IP (set after getIP, used for TUN creation)
    assigned_ip: Arc<Mutex<Option<String>>>,
    /// DNS server parsed from VPN resources (set after getResources)
    dns_server: Arc<Mutex<Option<String>>>,
    /// DNS route IPs (mapped IPs from <Dns data>) to add to VPN routes
    dns_routes: Arc<Mutex<Option<String>>>,
}

/// Atomic traffic counters for lock-free access from relay threads
struct TrafficCounters {
    bytes_sent: AtomicU64,
    bytes_received: AtomicU64,
    packets_sent: AtomicU64,
    packets_received: AtomicU64,
}

impl TrafficCounters {
    fn new() -> Self {
        Self {
            bytes_sent: AtomicU64::new(0),
            bytes_received: AtomicU64::new(0),
            packets_sent: AtomicU64::new(0),
            packets_received: AtomicU64::new(0),
        }
    }

    fn snapshot(&self) -> VpnTrafficStats {
        VpnTrafficStats {
            bytes_sent: self.bytes_sent.load(Ordering::Relaxed),
            bytes_received: self.bytes_received.load(Ordering::Relaxed),
            packets_sent: self.packets_sent.load(Ordering::Relaxed),
            packets_received: self.packets_received.load(Ordering::Relaxed),
        }
    }
}

impl SangforVpnService {
    pub fn new(config: VpnConfig) -> Self {
        SangforVpnService {
            config: Arc::new(Mutex::new(config)),
            state: Arc::new(Mutex::new(VpnState::Disconnected)),
            running: Arc::new(AtomicBool::new(false)),
            client: Arc::new(Mutex::new(None)),
            stream_sink: Arc::new(Mutex::new(None)),
            last_error: Arc::new(Mutex::new(None)),
            tun_fd: Arc::new(Mutex::new(None)),
            traffic: Arc::new(TrafficCounters::new()),
            assigned_ip: Arc::new(Mutex::new(None)),
            dns_server: Arc::new(Mutex::new(None)),
            dns_routes: Arc::new(Mutex::new(None)),
        }
    }

    pub fn set_stream_sink(&mut self, sink: StreamSink<VpnState>) {
        *self.stream_sink.lock() = Some(sink);
    }

    /// On Android, set the TUN fd obtained from VpnService.Builder.establish().
    /// Must be called before connect() on Android targets.
    pub fn set_tun_fd(&self, fd: i32) {
        *self.tun_fd.lock() = Some(fd);
    }

    pub fn get_state(&self) -> VpnState {
        self.state.lock().clone()
    }

    pub fn get_config(&self) -> VpnConfig {
        self.config.lock().clone()
    }

    /// Returns the last error message, if any
    pub fn get_last_error(&self) -> Option<String> {
        self.last_error.lock().clone()
    }

    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::Relaxed)
    }

    fn set_state(&self, state: VpnState) {
        *self.state.lock() = state.clone();
        if let Some(ref sink) = *self.stream_sink.lock() {
            let _ = sink.add(state);
        }
    }

    /// 连接 VPN（阻塞，在后台线程中运行）
    pub fn connect(&mut self) -> Result<(), String> {
        if self.running.load(Ordering::Relaxed) {
            return Err("VPN is already running".to_string());
        }

        // Clear last error on new connection attempt
        *self.last_error.lock() = None;

        let config = self.config.lock().clone();
        let running = self.running.clone();
        let state = self.state.clone();
        let client = self.client.clone();
        let stream_sink = self.stream_sink.clone();
        let tun_fd = self.tun_fd.clone();
        let last_error = self.last_error.clone();
        let traffic = self.traffic.clone();
        let assigned_ip = self.assigned_ip.clone();

        self.running.store(true, Ordering::Relaxed);

        thread::spawn(move || {
            let result = panic::catch_unwind(AssertUnwindSafe(|| {
                Self::run_connection(
                    config, running.clone(), state.clone(), client.clone(),
                    stream_sink.clone(), tun_fd, traffic, assigned_ip,
                )
            }));

            match result {
                Ok(Ok(())) => {
                    // Connected successfully — run_connection already emitted
                    // VpnState::Connected before starting the relay.
                    // The relay thread runs until running is set to false.
                }
                Ok(Err(e)) => {
                    // Connection failed with a normal error
                    let msg = format!("{:#}", e);
                    error!("VPN connection failed: {}", msg);
                    android_log(&format!("VPN ERROR: {}", msg));
                    *last_error.lock() = Some(msg.clone());
                    *state.lock() = VpnState::Error;
                    if let Some(ref sink) = *stream_sink.lock() {
                        let _ = sink.add(VpnState::Error);
                    }
                    running.store(false, Ordering::Relaxed);
                }
                Err(panic_payload) => {
                    // Thread panicked (e.g., Go crash, CGo segfault, TUN error)
                    let msg = if let Some(s) = panic_payload.downcast_ref::<&str>() {
                        s.to_string()
                    } else if let Some(s) = panic_payload.downcast_ref::<String>() {
                        s.clone()
                    } else {
                        "internal error".to_string()
                    };
                    error!("VPN connection panicked: {}", msg);
                    android_log(&format!("VPN PANIC: {}", msg));
                    *last_error.lock() = Some(msg.clone());
                    *state.lock() = VpnState::Error;
                    if let Some(ref sink) = *stream_sink.lock() {
                        let _ = sink.add(VpnState::Error);
                    }
                    running.store(false, Ordering::Relaxed);
                }
            }
        });

        Ok(())
    }

    fn run_connection(
        config: VpnConfig,
        running: Arc<AtomicBool>,
        state: Arc<Mutex<VpnState>>,
        client: Arc<Mutex<Option<GoVpnClient>>>,
        stream_sink: Arc<Mutex<Option<StreamSink<VpnState>>>>,
        tun_fd: Arc<Mutex<Option<i32>>>,
        traffic: Arc<TrafficCounters>,
        assigned_ip: Arc<Mutex<Option<String>>>,
    ) -> Result<()> {
        let set_state = |s: VpnState| {
            *state.lock() = s.clone();
            if let Some(ref sink) = *stream_sink.lock() {
                let _ = sink.add(s);
            }
        };

        // Step 1: Create Go client
        set_state(VpnState::Connecting);
        android_log("VPN: connecting, creating Go client...");
        let mut go_client = GoVpnClient::new(
            &config.server,
            &config.username,
            &config.password,
            &config.totp_secret,
        );
        *client.lock() = Some(go_client);
        // We take it out again to use mutable ref... use client arc
        drop(client.lock());

        macro_rules! with_client {
            ($c:ident, $($e:tt)*) => {{
                let mut guard = client.lock();
                let $c = guard.as_mut().context("client not initialized")?;
                let result: Result<(), String> = $($e)*;
                result.map_err(|e| anyhow::anyhow!(e))
            }};
        }

        // Step 2: Login start
        set_state(VpnState::LoginStart);
        android_log("VPN: login_start...");
        with_client!(c, c.login_start())?;
        android_log("VPN: login_start OK");

        // Step 3: Login password
        set_state(VpnState::LoginPassword);
        android_log("VPN: login_password...");
        let pwd_result = with_client!(c, c.login_password()
            .map_err(|e| {
                if e.contains("SMS_REQUIRED") {
                    set_state(VpnState::WaitingSms);
                    "SMS_REQUIRED".to_string()
                } else if e.contains("TOTP_REQUIRED") {
                    set_state(VpnState::WaitingTotp);
                    "TOTP_REQUIRED".to_string()
                } else {
                    format!("Login password failed: {}", e)
                }
            })
        );

        match pwd_result {
            Ok(_) => {}
            Err(e) => {
                let msg = e.to_string();
                if msg.contains("SMS_REQUIRED") || msg.contains("TOTP_REQUIRED") {
                    info!("Waiting for 2FA code...");
                    return Ok(());
                }
                return Err(e);
            }
        }

        // Step 4: Get token
        set_state(VpnState::GettingToken);
        android_log("VPN: get_token...");
        with_client!(c, c.get_token())?;
        android_log("VPN: get_token OK");

        // Step 5: Get resources
        set_state(VpnState::GettingResources);
        android_log("VPN: get_resources...");
        with_client!(c, {
            c.get_resources().map(|_| ())
        })?;
        android_log("VPN: get_resources OK");

        // Step 6: Get IP
        set_state(VpnState::GettingIp);
        android_log("VPN: get_ip...");
        with_client!(c, c.get_ip())?;
        android_log("VPN: get_ip OK");

        // Read and store the server-assigned IP
        let server_ip = {
            let guard = client.lock();
            let c = guard.as_ref().context("client not initialized")?;
            c.get_assigned_ip().context("no IP assigned by server")?
        };
        *assigned_ip.lock() = Some(server_ip.clone());
        android_log(&format!("VPN: server assigned IP = {}", server_ip));

        // Step 7: Open data channels
        set_state(VpnState::OpeningChannels);
        android_log("VPN: open_data_channels...");
        with_client!(c, c.open_data_channels())?;
        android_log("VPN: open_data_channels OK");

        // Step 8: Create TUN device
        #[cfg(not(target_os = "android"))]
        let tun = Self::create_tun_with_ip(&config, &server_ip)?;

        #[cfg(target_os = "android")]
        let tun = {
            let fd = *tun_fd.lock();
            let fd = fd.ok_or_else(|| anyhow::anyhow!("Android: tun fd not set. Call set_tun_fd() before connect()."))?;
            unsafe { tun_rs::SyncDevice::from_fd(fd) }
                .context("failed to create TUN from fd")?
        };

        info!("TUN device created");

        // Step 9: Start data relay
        set_state(VpnState::Connected);
        info!("VPN connected successfully");

        Self::run_tun_relay(
            tun,
            client.clone(),
            running.clone(),
            traffic,
            server_ip.clone(),
            config.tun_address.clone(),
            "10.255.255.1".to_string(),
            Arc::new(std::collections::HashMap::new()),
        )?;

        Ok(())
    }

    /// Submit 2FA code (SMS or TOTP)
    pub fn submit_2fa(&self, code: &str) -> Result<(), String> {
        let current_state = self.state.lock().clone();
        match current_state {
            VpnState::WaitingSms => {
                let mut guard = self.client.lock();
                let c = guard.as_mut().ok_or("client not initialized")?;
                c.set_sms_code(code);
                c.login_sms().map_err(|e| format!("SMS login failed: {}", e))?;
                drop(guard);

                // Continue with token, resources, IP, channels
                self.continue_after_2fa()
            }
            VpnState::WaitingTotp => {
                let mut guard = self.client.lock();
                let c = guard.as_mut().ok_or("client not initialized")?;
                c.set_sms_code(code);
                c.login_totp().map_err(|e| format!("TOTP login failed: {}", e))?;
                drop(guard);

                self.continue_after_2fa()
            }
            _ => Err("Not waiting for 2FA code".to_string()),
        }
    }

    fn continue_after_2fa(&self) -> Result<(), String> {
        self.set_state(VpnState::GettingToken);

        let mut guard = self.client.lock();
        let c = guard.as_mut().ok_or("client not initialized")?;
        c.get_token().map_err(|e| format!("Get token failed: {}", e))?;

        self.set_state(VpnState::GettingResources);
        let _resources = c.get_resources().map_err(|e| format!("Get resources failed: {}", e))?;

        self.set_state(VpnState::GettingIp);
        c.get_ip().map_err(|e| format!("Get IP failed: {}", e))?;

        // Read the server-assigned IP
        let server_ip = c.get_assigned_ip().ok_or("no IP assigned by server")?;
        *self.assigned_ip.lock() = Some(server_ip.clone());
        android_log(&format!("VPN (continue_after_2fa): server IP = {}", server_ip));

        self.set_state(VpnState::OpeningChannels);
        c.open_data_channels().map_err(|e| format!("Open channels failed: {}", e))?;
        drop(guard);

        // Create TUN and start relay
        #[cfg(not(target_os = "android"))]
        let tun = {
            let config = self.config.lock();
            Self::create_tun_with_ip(&config, &server_ip)
                .map_err(|e| format!("TUN create failed: {}", e))?
        };

        #[cfg(target_os = "android")]
        let tun = {
            let fd = *self.tun_fd.lock();
            let fd = fd.ok_or("Android: tun fd not set. Call set_tun_fd() before connect().")?;
            unsafe { tun_rs::SyncDevice::from_fd(fd) }
                .map_err(|e| format!("TUN create from fd failed: {}", e))?
        };

        self.set_state(VpnState::Connected);

        let client = self.client.clone();
        let running = self.running.clone();
        let traffic = self.traffic.clone();
        let config = self.config.lock().clone();
        let assigned = server_ip.clone();

        std::thread::spawn(move || {
            let _ = Self::run_tun_relay(tun, client, running, traffic, assigned, config.tun_address, "10.255.255.1".to_string(), Arc::new(std::collections::HashMap::new()));
        });

        Ok(())
    }

    /// 断开 VPN
    pub fn disconnect(&mut self) {
        self.running.store(false, Ordering::Relaxed);
        self.set_state(VpnState::Disconnected);
        // Reset traffic counters
        self.traffic.bytes_sent.store(0, Ordering::Relaxed);
        self.traffic.bytes_received.store(0, Ordering::Relaxed);
        self.traffic.packets_sent.store(0, Ordering::Relaxed);
        self.traffic.packets_received.store(0, Ordering::Relaxed);
        // Client will be dropped when Arc ref count reaches 0
    }

    pub fn get_traffic_stats(&self) -> VpnTrafficStats {
        self.traffic.snapshot()
    }

    /// Returns the server-assigned IP (available after getIP step completes)
    pub fn get_assigned_ip(&self) -> Option<String> {
        self.assigned_ip.lock().clone()
    }

    /// Returns the DNS server parsed from VPN resources (available after getResources)
    pub fn get_dns_server(&self) -> Option<String> {
        self.dns_server.lock().clone()
    }

    /// Returns DNS route IPs (unique mapped IPs from <Dns data>),
    /// comma-separated, for adding as /32 VPN routes.
    pub fn get_dns_routes(&self) -> Option<String> {
        self.dns_routes.lock().clone()
    }

    /// Phase 1: Authenticate and retrieve the server-assigned IP.
    ///
    /// This runs the auth flow up through getIP and returns the IP string.
    /// If 2FA is required, returns Err("SMS_REQUIRED") or Err("TOTP_REQUIRED").
    /// Call `continue_auth_after_2fa_and_get_ip()` after submitting the 2FA code.
    ///
    /// This method blocks during network I/O; call from a background thread.
    pub fn authenticate_and_get_ip(&self) -> Result<String, String> {
        if self.running.load(Ordering::Relaxed) {
            return Err("VPN is already running".to_string());
        }

        let config = self.config.lock().clone();
        let client = self.client.clone();
        let state = self.state.clone();
        let stream_sink = self.stream_sink.clone();
        let assigned_ip = self.assigned_ip.clone();
        let dns_server = self.dns_server.clone();

        self.running.store(true, Ordering::Relaxed);

        let set_state = |s: VpnState| {
            *state.lock() = s.clone();
            if let Some(ref sink) = *stream_sink.lock() {
                let _ = sink.add(s);
            }
        };

        // Step 1: Create Go client
        set_state(VpnState::Connecting);
        let go_client = GoVpnClient::new(
            &config.server,
            &config.username,
            &config.password,
            &config.totp_secret,
        );
        *client.lock() = Some(go_client);
        drop(client.lock());

        macro_rules! with_client {
            ($c:ident, $($e:tt)*) => {{
                let mut guard = client.lock();
                let $c = guard.as_mut().ok_or("client not initialized")?;
                $($e)*
            }};
        }

        // Step 2: Login start
        set_state(VpnState::LoginStart);
        with_client!(c, c.login_start().map_err(|e| format!("login_start: {}", e)))?;

        // Step 3: Login password
        set_state(VpnState::LoginPassword);
        let pwd_result = with_client!(c, {
            c.login_password().map_err(|e| {
                if e.contains("SMS_REQUIRED") {
                    set_state(VpnState::WaitingSms);
                    "SMS_REQUIRED".to_string()
                } else if e.contains("TOTP_REQUIRED") {
                    set_state(VpnState::WaitingTotp);
                    "TOTP_REQUIRED".to_string()
                } else {
                    format!("Login password failed: {}", e)
                }
            })
        });

        match pwd_result {
            Ok(_) => {}
            Err(e) => {
                if e.contains("SMS_REQUIRED") || e.contains("TOTP_REQUIRED") {
                    return Err(e);
                }
                self.running.store(false, Ordering::Relaxed);
                return Err(e);
            }
        }

        // Step 4: Get token
        set_state(VpnState::GettingToken);
        with_client!(c, c.get_token().map_err(|e| format!("get_token: {}", e)))?;

        // Step 5: Get resources
        set_state(VpnState::GettingResources);
        with_client!(c, c.get_resources().map_err(|e| format!("get_resources: {}", e)))?;

        // Extract DNS server parsed from resources
        {
            let guard = client.lock();
            let c = guard.as_ref().ok_or("client not initialized")?;
            let parsed_dns = c.get_dns_server();
            let dns_str = parsed_dns.clone().unwrap_or_default();
            if !dns_str.is_empty() {
                android_log(&format!("VPN: campus DNS = {}", dns_str));
                // Override custom_dns with campus DNS
                let mut cfg = self.config.lock();
                cfg.custom_dns = Some(dns_str);
            } else {
                android_log("VPN: no campus DNS found in resources");
            }
            *dns_server.lock() = parsed_dns;
        let parsed_routes = c.get_dns_routes();
        if parsed_routes.as_ref().map_or(false, |r| !r.is_empty()) {
            android_log(&format!("VPN: dns routes = {}", parsed_routes.as_ref().unwrap()));
        }
        *self.dns_routes.lock() = parsed_routes;
        }

        // Step 6: Get IP
        set_state(VpnState::GettingIp);
        with_client!(c, c.get_ip().map_err(|e| format!("get_ip: {}", e)))?;

        // Read the assigned IP from the Go client
        let ip = {
            let guard = client.lock();
            let c = guard.as_ref().ok_or("client not initialized")?;
            c.get_assigned_ip().ok_or("no IP assigned by server")?
        };

        *assigned_ip.lock() = Some(ip.clone());
        android_log(&format!("VPN: server assigned IP = {}", ip));

        Ok(ip)
    }

    /// Continue authentication after 2FA and return the server-assigned IP.
    /// Called after the user submits their SMS/TOTP code via `submit_2fa_code()`.
    pub fn continue_auth_after_2fa_and_get_ip(&self, code: &str) -> Result<String, String> {
        let current_state = self.state.lock().clone();
        let client = self.client.clone();
        let state = self.state.clone();
        let stream_sink = self.stream_sink.clone();
        let assigned_ip = self.assigned_ip.clone();
        let dns_server = self.dns_server.clone();

        let set_state = |s: VpnState| {
            *state.lock() = s.clone();
            if let Some(ref sink) = *stream_sink.lock() {
                let _ = sink.add(s);
            }
        };

        match current_state {
            VpnState::WaitingSms => {
                let mut guard = client.lock();
                let c = guard.as_mut().ok_or("client not initialized")?;
                c.set_sms_code(code);
                c.login_sms().map_err(|e| format!("SMS login failed: {}", e))?;
                drop(guard);
            }
            VpnState::WaitingTotp => {
                let mut guard = client.lock();
                let c = guard.as_mut().ok_or("client not initialized")?;
                c.set_sms_code(code);
                c.login_totp().map_err(|e| format!("TOTP login failed: {}", e))?;
                drop(guard);
            }
            _ => return Err("Not waiting for 2FA code".to_string()),
        }

        // Get token
        set_state(VpnState::GettingToken);
        {
            let mut guard = client.lock();
            let c = guard.as_mut().ok_or("client not initialized")?;
            c.get_token().map_err(|e| format!("get_token: {}", e))?;
        }

        // Get resources
        set_state(VpnState::GettingResources);
        {
            let mut guard = client.lock();
            let c = guard.as_mut().ok_or("client not initialized")?;
            c.get_resources().map_err(|e| format!("get_resources: {}", e))?;
        }

        // Extract DNS server parsed from resources
        {
            let guard = client.lock();
            let c = guard.as_ref().ok_or("client not initialized")?;
            let parsed_dns = c.get_dns_server();
            if let Some(ref dns) = parsed_dns {
                android_log(&format!("VPN (2FA): campus DNS = {}", dns));
                let mut cfg = self.config.lock();
                cfg.custom_dns = Some(dns.clone());
            }
            *dns_server.lock() = parsed_dns;
            let parsed_routes = c.get_dns_routes();
            if parsed_routes.as_ref().map_or(false, |r| !r.is_empty()) {
                android_log(&format!("VPN (2FA): dns routes = {}", parsed_routes.as_ref().unwrap()));
            }
            *self.dns_routes.lock() = parsed_routes;
        }

        // Get IP
        set_state(VpnState::GettingIp);
        {
            let mut guard = client.lock();
            let c = guard.as_mut().ok_or("client not initialized")?;
            c.get_ip().map_err(|e| format!("get_ip: {}", e))?;
        }

        // Read the assigned IP
        let ip = {
            let guard = client.lock();
            let c = guard.as_ref().ok_or("client not initialized")?;
            c.get_assigned_ip().ok_or("no IP assigned by server")?
        };

        *assigned_ip.lock() = Some(ip.clone());
        android_log(&format!("VPN (after 2FA): server assigned IP = {}", ip));

        Ok(ip)
    }

    /// Phase 2: Open data channels and start TUN relay.
    ///
    /// Must be called after `authenticate_and_get_ip()` (or `continue_auth_after_2fa_and_get_ip()`)
    /// and after the TUN device has been created with the correct IP.
    /// On Android, `set_tun_fd()` must have been called with the TUN fd.
    pub fn open_channels_and_relay(&self) -> Result<(), String> {
        let client = self.client.clone();
        let state = self.state.clone();
        let stream_sink = self.stream_sink.clone();
        let running = self.running.clone();
        let tun_fd = self.tun_fd.clone();
        let traffic = self.traffic.clone();
        let config = self.config.lock().clone();

        let set_state = |s: VpnState| {
            *state.lock() = s.clone();
            if let Some(ref sink) = *stream_sink.lock() {
                let _ = sink.add(s);
            }
        };

        // Open data channels
        set_state(VpnState::OpeningChannels);
        {
            let mut guard = client.lock();
            let c = guard.as_mut().ok_or("client not initialized")?;
            c.open_data_channels().map_err(|e| format!("open_data_channels: {}", e))?;
        }

        // Create TUN device
        #[cfg(not(target_os = "android"))]
        let tun = {
            let ip = self.assigned_ip.lock().clone()
                .unwrap_or_else(|| config.tun_address.clone());
            Self::create_tun_with_ip(&config, &ip)
                .map_err(|e| format!("TUN create failed: {}", e))?
        };

        #[cfg(target_os = "android")]
        let tun = {
            let fd = *tun_fd.lock();
            let fd = fd.ok_or("Android: tun fd not set")?;
            unsafe { tun_rs::SyncDevice::from_fd(fd) }
                .map_err(|e| format!("TUN create from fd failed: {}", e))?
        };

        info!("TUN device created for relay");

        // Mark connected and start relay
        set_state(VpnState::Connected);
        info!("VPN connected successfully");

        let assigned_for_relay = self.assigned_ip.lock().clone()
            .unwrap_or_else(|| config.tun_address.clone());
        let tun_for_relay = config.tun_address.clone();

        // Read DNS data mapping (domain->IP) for TUN-local DNS resolver
        let dns_data: Arc<std::collections::HashMap<String, String>> = {
            let guard = client.lock();
            if let Some(c) = guard.as_ref() {
                if let Some(data_str) = c.get_dns_data() {
                    let mut map = std::collections::HashMap::new();
                    for pair in data_str.split(';') {
                        if let Some((domain, ip)) = pair.split_once('=') {
                            map.insert(domain.to_string(), ip.to_string());
                        }
                    }
                    android_log(&format!("VPN: TUN DNS resolver loaded {} domain->IP mappings", map.len()));
                    Arc::new(map)
                } else {
                    android_log("VPN: no DNS data mapping, TUN DNS resolver disabled");
                    Arc::new(std::collections::HashMap::new())
                }
            } else {
                Arc::new(std::collections::HashMap::new())
            }
        };

        std::thread::spawn(move || {
            let _ = Self::run_tun_relay(tun, client, running, traffic, assigned_for_relay, tun_for_relay, "10.255.255.1".to_string(), dns_data);
        });

        Ok(())
    }

    // ========== Internal ==========

    #[cfg(not(target_os = "android"))]
    fn create_tun(config: &VpnConfig) -> Result<tun_rs::SyncDevice> {
        let addr: Ipv4Addr = config.tun_address.parse()
            .context("invalid tun_address")?;
        Self::create_tun_with_addr(config, addr)
    }

    #[cfg(not(target_os = "android"))]
    fn create_tun_with_ip(config: &VpnConfig, ip: &str) -> Result<tun_rs::SyncDevice> {
        let addr: Ipv4Addr = ip.parse()
            .context("invalid IP address")?;
        Self::create_tun_with_addr(config, addr)
    }

    #[cfg(not(target_os = "android"))]
    fn create_tun_with_addr(config: &VpnConfig, addr: Ipv4Addr) -> Result<tun_rs::SyncDevice> {
        let mut builder = tun_rs::DeviceBuilder::new();

        if let Some(ref name) = config.tun_name {
            builder = builder.name(name);
        }

        let prefix_len = parse_netmask_to_prefix(&config.tun_netmask)
            .context("invalid tun_netmask")?;

        let device = builder
            .ipv4(addr, prefix_len, None)
            .mtu(config.mtu)
            .build_sync()
            .context("failed to create TUN device")?;

        info!("TUN device created: {:?}, IP: {}", device.name(), addr);
        Ok(device)
    }

    fn run_tun_relay(
        tun: tun_rs::SyncDevice,
        client_arc: Arc<Mutex<Option<GoVpnClient>>>,
        running: Arc<AtomicBool>,
        traffic: Arc<TrafficCounters>,
        assigned_ip: String,
        tun_ip: String,
        dns_ip: String,
        dns_data: Arc<std::collections::HashMap<String, String>>,
    ) -> Result<()> {
        // Set TUN fd to non-blocking mode so recv() returns immediately
        #[cfg(target_os = "android")]
        {
            let raw_fd = tun.as_raw_fd();
            unsafe {
                let flags = libc::fcntl(raw_fd, libc::F_GETFL, 0);
                if flags != -1 {
                    libc::fcntl(raw_fd, libc::F_SETFL, flags | libc::O_NONBLOCK);
                    android_log(&format!("TUN relay: set non-blocking mode on fd {}", raw_fd));
                }
            }
        }

        let tun_arc = Arc::new(Mutex::new(tun));
        let tun_send = tun_arc.clone();
        let tun_recv = tun_arc.clone();

        // Parse the assigned IP and TUN IP once for NAT rewriting
        let assigned_ip_bytes = parse_ipv4_to_bytes(&assigned_ip);
        let tun_ip_bytes = parse_ipv4_to_bytes(&tun_ip);
        let dns_ip_bytes = parse_ipv4_to_bytes(&dns_ip);
        let do_nat = assigned_ip_bytes.is_some()
            && tun_ip_bytes.is_some()
            && assigned_ip_bytes != tun_ip_bytes;

        android_log(&format!(
            "TUN relay: tun_ip={} assigned_ip={} dns_ip={} do_nat={}",
            tun_ip, assigned_ip, dns_ip, do_nat
        ));
        info!("TUN relay: tun_ip={} assigned_ip={} do_nat={}", tun_ip, assigned_ip, do_nat);

        if do_nat {
            android_log(&format!(
                "TUN relay: NAT enabled, rewriting {} -> {}",
                tun_ip, assigned_ip
            ));
            info!("TUN relay: source NAT {} -> {}", tun_ip, assigned_ip);
        }

        // Thread 1: TUN → VPN Send (reads from TUN, writes to sendConn)
        //
        // IMPORTANT: We extract the Go client ID before calling FFI, so we never
        // hold the Rust mutex during FFI calls. The Go side has its own per-
        // connection locks (sendLock/recvLock) for thread safety.
        //
        // Source NAT: If the TUN IP differs from the server-assigned IP, we
        // rewrite the source IP in outgoing IPv4 packets so the VPN server
        // recognizes them as belonging to our session. Without this, the
        // server silently drops packets and Received stays at 0.
        let client_send = client_arc.clone();
        let running_send = running.clone();
        let traffic_send = traffic.clone();
        let assigned_send = assigned_ip_bytes;
        let tun_send_ip = tun_ip_bytes;
        let dns_send = dns_data.clone();
        let tun_recv_ref = tun_recv.clone();
        let send_thread = thread::spawn(move || {
            let mut buf = vec![0u8; 1500];
            let mut pkt_count: u64 = 0;
            let mut dropped: u64 = 0;
            let mut dns_handled: u64 = 0;
            let mut idle: u64 = 0;
            let mut consecutive_empty: u64 = 0;
            let mut logged_real_traffic = false;
            while running_send.load(Ordering::Relaxed) {
                let n = {
                    let t = tun_send.lock();
                    match t.recv(&mut buf) {
                        Ok(n) => n,
                        Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => 0,
                        Err(e) => {
                            idle += 1;
                            if idle <= 3 || idle % 500 == 0 {
                                android_log(&format!(
                                    "TUN->send recv ERROR#{}: {} kind={:?}",
                                    idle, e, e.kind()
                                ));
                            }
                            0
                        }
                    }
                };
                if n > 0 {
                    // ===== TUN-local DNS resolver =====
                    // Intercept DNS queries (UDP port 53) destined for our virtual DNS IP
                    // and respond with mapped IPs from the VPN resource data.
                    let dns_ip_check = dns_ip_bytes.unwrap_or([10, 255, 255, 1]);
                    if is_dns_query_to_self(&buf, n, dns_ip_check) {
                        let ihl = ((buf[0] & 0x0F) * 4) as usize;
                        let dns_query = &buf[ihl + 8..n];
                        if let Some(domain) = parse_dns_qname(&buf, ihl) {
                            if let Some(ip_str) = dns_send.get(&domain) {
                                if let Some(ip_bytes) = parse_ipv4_to_bytes(ip_str) {
                                    if let Some(dns_resp) = build_dns_response(dns_query, ip_bytes) {
                                        let ok = write_dns_response_to_tun(
                                            &tun_recv_ref, &buf[..n], &dns_resp, traffic_send.clone()
                                        );
                                        dns_handled += 1;
                                        if dns_handled <= 10 || dns_handled % 50 == 0 {
                                            android_log(&format!(
                                                "DNS: resolved {} -> {} (handled={}) {}",
                                                domain, ip_str, dns_handled,
                                                if ok { "OK" } else { "FAIL" }
                                            ));
                                        }
                                    }
                                }
                                continue;
                            }
                            // Unknown domain: respond with SERVFAIL so Android falls back
                            // to public DNS via normal network immediately
                            if let Some(empty_resp) = build_dns_empty_response(dns_query) {
                                let _ = write_dns_response_to_tun(
                                    &tun_recv_ref, &buf[..n], &empty_resp, traffic_send.clone()
                                );
                            }
                            if dns_handled < 3 {
                                android_log(&format!(
                                    "DNS: unknown domain '{}' (returning SERVFAIL)",
                                    domain
                                ));
                            }
                            dns_handled += 1;
                            continue;
                        }
                        // Always continue — don't send DNS queries to VPN server
                        continue;
                    }
                    // ===== End DNS resolver =====

                    if n < 4 || (buf[0] >> 4) != 4 {
                        dropped += 1;
                        if dropped == 1 || dropped <= 3 || dropped % 100 == 0 {
                            let first_bytes: Vec<String> = buf[..n.min(8)].iter()
                                .map(|b| format!("0x{:02x}", b))
                                .collect();
                            android_log(&format!(
                                "TUN->send DROP#{}: len={} ver=0x{:02x} proto={} bytes=[{}]",
                                dropped, n, buf[0] >> 4, buf[9],
                                first_bytes.join(", ")
                            ));
                        }
                        continue;
                    }
                    pkt_count += 1;
                    consecutive_empty = 0;

                    if pkt_count <= 10 {
                        let src = fmt_ipv4_header(&buf[..n], 12);
                        let dst = fmt_ipv4_header(&buf[..n], 16);
                        let (proto, sport, dport) = parse_ipv4_ports(&buf[..n]);
                        android_log(&format!(
                            "TUN->send pkt#{}: len={} src={} dst={} proto={} sport={} dport={}",
                            pkt_count, n, src, dst, proto, sport, dport
                        ));
                    }

                    // Log the first packet with a non-zero source IP (real user traffic)
                    if !logged_real_traffic && n >= 16 {
                        let src = [buf[12], buf[13], buf[14], buf[15]];
                        if src != [0, 0, 0, 0] {
                            logged_real_traffic = true;
                            let dst = fmt_ipv4_header(&buf[..n], 16);
                            let (proto, sport, dport) = parse_ipv4_ports(&buf[..n]);
                            android_log(&format!(
                                "TUN->send pkt#{}: FIRST REAL TRAFFIC src={}.{}.{}.{} dst={} proto={} sport={} dport={}",
                                pkt_count, src[0], src[1], src[2], src[3], dst, proto, sport, dport
                            ));
                        }
                    }

                    if do_nat {
                        if let (Some(assigned), Some(tun)) = (assigned_send, tun_send_ip) {
                            nat_rewrite_source_ipv4(&mut buf[..n], tun, assigned);
                            if pkt_count <= 5 {
                                let src_after = fmt_ipv4_header(&buf[..n], 12);
                                android_log(&format!(
                                    "TUN->send pkt#{}: NAT {} -> {}",
                                    pkt_count,
                                    fmt_ipv4_bytes(&tun),
                                    src_after
                                ));
                            }
                        }
                    }
                    let id = {
                        client_send.lock().as_ref().map(|c| c.id).unwrap_or(-1)
                    };
                    if id >= 0 {
                        let ret = unsafe {
                            ffi::EC_WriteSend(id, buf.as_ptr() as *const c_void, n as c_int)
                        };
                        if pkt_count <= 5 {
                            let hex_str: String = buf[..n.min(80)]
                                .iter()
                                .map(|b| format!("{:02x}", b))
                                .collect::<Vec<_>>()
                                .join("");
                            android_log(&format!(
                                "TUN->send pkt#{}: EC_WriteSend ret={} hex={}",
                                pkt_count, ret, hex_str
                            ));
                        }
                        if ret < 0 {
                            if pkt_count <= 5 || pkt_count % 20 == 0 {
                                android_log(&format!(
                                    "TUN->send ERROR: EC_WriteSend failed ret={} pkt#{}",
                                    ret, pkt_count
                                ));
                            }
                        }
                        if ret >= 0 {
                            traffic_send.bytes_sent.fetch_add(ret as u64, Ordering::Relaxed);
                            traffic_send.packets_sent.fetch_add(1, Ordering::Relaxed);
                        }
                    }
                } else {
                    idle += 1;
                    consecutive_empty += 1;
                    if idle % 500 == 0 {
                        android_log(&format!(
                            "TUN->send IDLE: {} empty reads, {} pkt sent, {} dns, {} dropped",
                            idle, pkt_count, dns_handled, dropped
                        ));
                    }
                    if consecutive_empty < 10 {
                        thread::sleep(Duration::from_millis(1));
                    } else if consecutive_empty < 100 {
                        thread::sleep(Duration::from_millis(10));
                    } else {
                        thread::sleep(Duration::from_millis(50));
                    }
                }
            }
        });

        // Thread 2: VPN Recv → TUN (reads from recvConn, writes to TUN)
        //
        // IMPORTANT: recvConn.Read() is a blocking TLS read. We must NOT hold
        // the Rust mutex during this call, otherwise the send thread is deadlocked
        // and can never send the initial packet that would trigger a server response.
        let client_recv = client_arc.clone();
        let running_recv = running.clone();
        let traffic_recv = traffic.clone();
        let assigned_recv = assigned_ip_bytes;
        let tun_recv_ip = tun_ip_bytes;
        let recv_thread = thread::spawn(move || {
            let mut buf = vec![0u8; 1500];
            let mut recv_count: u64 = 0;
            let mut err_count: u64 = 0;
            android_log("recv->TUN thread: started, waiting for data from recvConn...");
            while running_recv.load(Ordering::Relaxed) {
                // Extract client id before blocking read
                let id = {
                    client_recv.lock().as_ref().map(|c| c.id).unwrap_or(-1)
                };
                if id < 0 {
                    thread::sleep(Duration::from_millis(10));
                    continue;
                }
                // Call FFI directly — no lock held during the blocking read
                let n = unsafe {
                    if recv_count == 0 && err_count == 0 {
                        android_log(&format!(
                            "recv->TUN: calling EC_ReadRecv(id={})...",
                            id
                        ));
                    }
                    ffi::EC_ReadRecv(id, buf.as_mut_ptr() as *mut c_void, buf.len() as c_int)
                };
                if n > 0 {
                    recv_count += 1;
                    if recv_count <= 5 {
                        let src = fmt_ipv4_header(&buf[..n as usize], 12);
                        let dst = fmt_ipv4_header(&buf[..n as usize], 16);
                        let (proto, sport, dport) = parse_ipv4_ports(&buf[..n as usize]);
                        android_log(&format!(
                            "recv->TUN pkt#{}: len={} src={} dst={} proto={} sport={} dport={}",
                            recv_count, n, src, dst, proto, sport, dport
                        ));
                    }
                    // Reverse NAT: rewrite destination IP from server-assigned
                    // IP back to TUN IP so the Android kernel recognizes it.
                    if let (Some(assigned), Some(tun)) = (assigned_recv, tun_recv_ip) {
                        nat_rewrite_dest_ipv4(&mut buf[..n as usize], assigned, tun);
                    }
                    let t = tun_recv.lock();
                    let _ = t.send(&buf[..n as usize]);
                    traffic_recv.bytes_received.fetch_add(n as u64, Ordering::Relaxed);
                    traffic_recv.packets_received.fetch_add(1, Ordering::Relaxed);
                } else {
                    err_count += 1;
                    if err_count <= 5 || err_count % 100 == 0 {
                        android_log(&format!(
                            "recv->TUN: EC_ReadRecv ret={} err_count={}",
                            n, err_count
                        ));
                    }
                    thread::sleep(Duration::from_millis(10));
                }
            }
        });

        let _ = send_thread.join();
        let _ = recv_thread.join();
        Ok(())
    }
}

impl Drop for SangforVpnService {
    fn drop(&mut self) {
        self.disconnect();
    }
}

/// Parse a netmask string (e.g., "255.255.255.0") to a prefix length (e.g., 24)
fn parse_netmask_to_prefix(netmask: &str) -> Result<u8> {
    let addr: Ipv4Addr = netmask.parse()
        .context("invalid netmask format")?;
    let octets = addr.octets();
    // Count leading 1 bits
    let bits = octets.iter()
        .map(|&b| b.count_ones())
        .sum::<u32>() as u8;
    if bits == 0 || bits > 32 {
        anyhow::bail!("invalid netmask: no bits set or too many bits");
    }
    // Verify it's a valid contiguous netmask
    let mask = u32::from_be_bytes(octets);
    let inverted = !mask;
    if inverted & (inverted + 1) != 0 {
        anyhow::bail!("invalid netmask: not a contiguous mask");
    }
    Ok(bits)
}

/// Log a message to Android logcat (tag: rust_lib_punklorde) so errors
/// are visible in `adb logcat` even if tracing is not configured.
/// On non-Android this is a no-op.
fn android_log(msg: &str) {
    #[cfg(target_os = "android")]
    {
        let tag = std::ffi::CString::new("rust_lib_punklorde").unwrap_or_default();
        let fmt = std::ffi::CString::new("%s").unwrap_or_default();
        let c_msg = std::ffi::CString::new(msg).unwrap_or_default();
        unsafe {
            android_log_sys::__android_log_print(
                6,
                tag.as_ptr(),
                fmt.as_ptr(),
                c_msg.as_ptr(),
            );
        }
    }
    #[cfg(not(target_os = "android"))]
    {
        let _ = msg;
    }
}

/// Parse an IPv4 address string (e.g., "10.0.0.2") into [u8; 4].
/// Returns None if the string is not a valid IPv4 address.
fn parse_ipv4_to_bytes(ip: &str) -> Option<[u8; 4]> {
    let addr: Ipv4Addr = ip.parse().ok()?;
    Some(addr.octets())
}

fn fmt_ipv4_bytes(bytes: &[u8; 4]) -> String {
    format!("{}.{}.{}.{}", bytes[0], bytes[1], bytes[2], bytes[3])
}

fn fmt_ipv4_header(packet: &[u8], offset: usize) -> String {
    if packet.len() < offset + 4 {
        return "N/A".to_string();
    }
    format!(
        "{}.{}.{}.{}",
        packet[offset],
        packet[offset + 1],
        packet[offset + 2],
        packet[offset + 3]
    )
}

fn parse_ipv4_ports(packet: &[u8]) -> (&'static str, u16, u16) {
    if packet.len() < 20 {
        return ("?", 0, 0);
    }
    let version_ihl = packet[0];
    if (version_ihl >> 4) != 4 {
        return ("?", 0, 0);
    }
    let ihl = (version_ihl & 0x0F) as usize * 4;
    if packet.len() < ihl + 4 {
        return ("?", 0, 0);
    }
    let protocol = packet[9];
    let src_port = u16::from_be_bytes([packet[ihl], packet[ihl + 1]]);
    let dst_port = u16::from_be_bytes([packet[ihl + 2], packet[ihl + 3]]);
    let proto_name = match protocol {
        1 => "ICMP",
        6 => "TCP",
        17 => "UDP",
        _ => "?",
    };
    (proto_name, src_port, dst_port)
}

/// Rewrite the source IP address in an IPv4 packet.
///
/// Modifies the IPv4 header source address from `from` to `to` and
/// recalculates the IPv4 header checksum. For TCP and UDP packets,
/// also recalculates the transport-layer checksum (which covers the
/// pseudo-header containing the source/destination IPs).
fn nat_rewrite_source_ipv4(packet: &mut [u8], from: [u8; 4], to: [u8; 4]) {
    if packet.len() < 20 {
        return;
    }

    let version_ihl = packet[0];
    if (version_ihl >> 4) != 4 {
        return;
    }

    let ihl = (version_ihl & 0x0F) as usize * 4;
    if packet.len() < ihl {
        return;
    }

    let total_length = u16::from_be_bytes([packet[2], packet[3]]) as usize;
    if total_length > packet.len() {
        return;
    }

    let src = &packet[12..16];
    let actual_src: [u8; 4] = [packet[12], packet[13], packet[14], packet[15]];
    let zero_ip: [u8; 4] = [0, 0, 0, 0];

    use std::sync::atomic::{AtomicBool, Ordering};
    static NAT_DBG: AtomicBool = AtomicBool::new(true);
    if NAT_DBG.load(Ordering::Relaxed) {
        NAT_DBG.store(false, Ordering::Relaxed);
        android_log(&format!(
            "NAT_DBG: pkt_len={} ver_ihl=0x{:02x} ihl={} total_len={} src=[{},{},{},{}] from=[{},{},{},{}] to=[{},{},{},{}]",
            packet.len(),
            version_ihl,
            ihl,
            total_length,
            src[0], src[1], src[2], src[3],
            from[0], from[1], from[2], from[3],
            to[0], to[1], to[2], to[3],
        ));
    }

    if src != &from && src != &zero_ip {
        return;
    }

    if src == &zero_ip {
        android_log(&format!(
            "NAT: rewriting 0.0.0.0 -> {}.{}.{}.{}",
            to[0], to[1], to[2], to[3]
        ));
    }

    // Rewrite source IP
    packet[12] = to[0];
    packet[13] = to[1];
    packet[14] = to[2];
    packet[15] = to[3];

    // Recalculate IPv4 header checksum
    // Zero out the checksum field first
    packet[10] = 0;
    packet[11] = 0;

    let mut sum: u32 = 0;
    for i in (0..ihl).step_by(2) {
        if i + 1 < ihl {
            sum += u16::from_be_bytes([packet[i], packet[i + 1]]) as u32;
        }
    }
    // Fold carries
    while sum > 0xFFFF {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }
    let checksum = !(sum as u16);
    packet[10] = (checksum >> 8) as u8;
    packet[11] = (checksum & 0xFF) as u8;

    // Recalculate TCP/UDP checksum (covers pseudo-header)
    let protocol = packet[9];
    if protocol != 6 && protocol != 17 {
        return;
    }

    let payload_offset = ihl;
    if total_length < payload_offset + 8 || total_length > packet.len() {
        return;
    }

    let transport_len = total_length - payload_offset;
    let transport = &mut packet[payload_offset..total_length];

    let old_checksum: u16;
    let csum_offset: usize;
    if protocol == 6 {
        // TCP: checksum is at offset 16-17 within the TCP header
        if transport_len < 18 {
            return;
        }
        old_checksum = u16::from_be_bytes([transport[16], transport[17]]);
        csum_offset = 16;
    } else if protocol == 17 {
        // UDP: checksum is at offset 6-7 within the UDP header
        if transport_len < 8 {
            return;
        }
        old_checksum = u16::from_be_bytes([transport[6], transport[7]]);
        csum_offset = 6;
    } else {
        return;
    }

    let old_src = u16::from_be_bytes([actual_src[0], actual_src[1]]) as u32
        + u16::from_be_bytes([actual_src[2], actual_src[3]]) as u32;
    let new_src = u16::from_be_bytes([to[0], to[1]]) as u32
        + u16::from_be_bytes([to[2], to[3]]) as u32;

    let delta = new_src.wrapping_sub(old_src);

    let mut csum = (!old_checksum) as u32;
    csum = csum.wrapping_add(delta);
    while csum > 0xFFFF {
        csum = (csum & 0xFFFF) + (csum >> 16);
    }
    let new_checksum = !(csum as u16);

    let final_checksum = if protocol == 17 && new_checksum == 0 {
        0xFFFFu16
    } else {
        new_checksum
    };

    transport[csum_offset] = (final_checksum >> 8) as u8;
    transport[csum_offset + 1] = (final_checksum & 0xFF) as u8;
}

// ========== DNS Resolution Helpers ==========

/// Check if an IPv4 packet is a DNS query (UDP port 53) destined for self (TUN IP)
fn is_dns_query_to_self(packet: &[u8], n: usize, tun_ip: [u8; 4]) -> bool {
    if n < 28 {
        return false;
    }
    if (packet[0] >> 4) != 4 {
        return false;
    }
    if packet[9] != 17 {
        return false;
    }
    let ihl = ((packet[0] & 0x0F) * 4) as usize;
    if n < ihl + 8 {
        return false;
    }
    if &packet[16..20] != &tun_ip {
        return false;
    }
    let dport = u16::from_be_bytes([packet[ihl + 2], packet[ihl + 3]]);
    dport == 53
}

/// Parse domain name from DNS query (QNAME: label format)
fn parse_dns_qname(packet: &[u8], ihl: usize) -> Option<String> {
    let udp_start = ihl + 8;
    let dns_payload = &packet[udp_start..];
    let mut pos: usize = 0;
    let mut parts: Vec<String> = Vec::new();

    while pos < dns_payload.len() {
        let len = dns_payload[pos] as usize;
        if len == 0 {
            break;
        }
        if (len & 0xC0) == 0xC0 {
            // Compressed name pointer — skip
            pos += 2;
            continue;
        }
        pos += 1;
        if pos + len > dns_payload.len() {
            return None;
        }
        let label = &dns_payload[pos..pos + len];
        parts.push(String::from_utf8_lossy(label).to_string());
        pos += len;
    }

    if parts.is_empty() {
        None
    } else {
        Some(parts.join("."))
    }
}

/// Build a DNS A record response. Returns (response_bytes, response_len).
/// The caller is responsible for wrapping it in IP/UDP headers.
fn build_dns_response(query: &[u8], ip: [u8; 4]) -> Option<Vec<u8>> {
    if query.len() < 12 {
        return None;
    }
    // Parse question section length: skip header + domain labels
    let mut pos = 12usize;
    while pos < query.len() {
        let len = query[pos] as usize;
        if len == 0 {
            pos += 1;
            break;
        }
        if (len & 0xC0) == 0xC0 {
            pos += 2;
            break;
        }
        pos += 1 + len;
    }
    if pos + 4 > query.len() {
        return None;
    }
    let qtype = u16::from_be_bytes([query[pos], query[pos + 1]]);
    let qclass = u16::from_be_bytes([query[pos + 2], query[pos + 3]]);

    // Only respond to A (type=1) and AAAA (type=28) queries
    // For AAAA, just respond with standard response but empty answer (NODATA)
    // For simplicity, only handle A queries now
    if qtype != 1 || qclass != 1 {
        return None;
    }

    let question_len = pos + 4 - 12; // bytes in question section (after header)
    let resp_len = 12 + question_len + 16; // header + question + answer
    let mut resp = vec![0u8; resp_len];

    // Copy transaction ID
    resp[0] = query[0];
    resp[1] = query[1];
    // Flags: response, standard query, no error
    resp[2] = 0x81;
    resp[3] = 0x80;
    // QDCOUNT = 1
    resp[4] = query[4];
    resp[5] = query[5];
    // ANCOUNT = 1
    resp[6] = 0x00;
    resp[7] = 0x01;
    // NSCOUNT = 0
    resp[8] = 0x00;
    resp[9] = 0x00;
    // ARCOUNT = 0
    resp[10] = 0x00;
    resp[11] = 0x00;

    // Copy question section
    let q_start = 12;
    resp[12..12 + question_len].copy_from_slice(&query[q_start..q_start + question_len]);

    // Answer section
    let a_start = 12 + question_len;
    // NAME: compressed pointer to offset 12 (0xc00c)
    resp[a_start] = 0xc0;
    resp[a_start + 1] = 0x0c;
    // TYPE: A (1)
    resp[a_start + 2] = 0x00;
    resp[a_start + 3] = 0x01;
    // CLASS: IN (1)
    resp[a_start + 4] = 0x00;
    resp[a_start + 5] = 0x01;
    // TTL: 60 seconds
    resp[a_start + 6] = 0x00;
    resp[a_start + 7] = 0x00;
    resp[a_start + 8] = 0x00;
    resp[a_start + 9] = 0x3c;
    // RDLENGTH: 4
    resp[a_start + 10] = 0x00;
    resp[a_start + 11] = 0x04;
    // RDATA: the IP
    resp[a_start + 12] = ip[0];
    resp[a_start + 13] = ip[1];
    resp[a_start + 14] = ip[2];
    resp[a_start + 15] = ip[3];

    Some(resp)
}

/// Build a DNS response with SERVFAIL (rcode=2) to tell Android
/// "I can't answer this" — prompting immediate fallback to the
/// next DNS server (public DNS) without waiting for timeout.
fn build_dns_empty_response(query: &[u8]) -> Option<Vec<u8>> {
    if query.len() < 12 {
        return None;
    }
    let mut pos = 12usize;
    while pos < query.len() {
        let len = query[pos] as usize;
        if len == 0 {
            pos += 1;
            break;
        }
        if (len & 0xC0) == 0xC0 {
            pos += 2;
            break;
        }
        pos += 1 + len;
    }
    if pos + 4 > query.len() {
        return None;
    }
    let question_len = pos + 4 - 12;
    let resp_len = 12 + question_len;
    let mut resp = vec![0u8; resp_len];

    resp[0] = query[0];
    resp[1] = query[1];
    resp[2] = 0x81;
    resp[3] = 0x82;
    resp[4] = query[4];
    resp[5] = query[5];
    resp[6] = 0x00;
    resp[7] = 0x00;
    resp[8] = 0x00;
    resp[9] = 0x00;
    resp[10] = 0x00;
    resp[11] = 0x00;

    let q_start = 12;
    resp[12..12 + question_len].copy_from_slice(&query[q_start..q_start + question_len]);

    Some(resp)
}

/// Write a pre-built DNS response payload back to TUN, wrapping in IP+UDP headers.
/// The original request packet is used as a template for swapping IPs/ports.
fn write_dns_response_to_tun(
    tun: &Mutex<tun_rs::SyncDevice>,
    request: &[u8],
    dns_payload: &[u8],
    traffic: Arc<TrafficCounters>,
) -> bool {
    if request.len() < 20 {
        return false;
    }
    let ihl = ((request[0] & 0x0F) * 4) as usize;
    if request.len() < ihl + 8 {
        return false;
    }

    let resp_total_len = ihl + 8 + dns_payload.len();
    let mut resp = vec![0u8; resp_total_len];

    // Copy IP header, swap src/dst
    resp[0..ihl].copy_from_slice(&request[0..ihl]);
    // Swap src and dst IP
    resp[12..16].copy_from_slice(&request[16..20]); // src = old dst
    resp[16..20].copy_from_slice(&request[12..16]);  // dst = old src
    // Update total length
    let total_len = resp_total_len as u16;
    resp[2] = (total_len >> 8) as u8;
    resp[3] = (total_len & 0xFF) as u8;
    // Recalc IP header checksum
    resp[10] = 0;
    resp[11] = 0;
    let mut sum: u32 = 0;
    for i in (0..ihl).step_by(2) {
        if i + 1 < ihl {
            sum += u16::from_be_bytes([resp[i], resp[i + 1]]) as u32;
        }
    }
    while sum > 0xFFFF {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }
    let checksum = !(sum as u16);
    resp[10] = (checksum >> 8) as u8;
    resp[11] = (checksum & 0xFF) as u8;

    // UDP header: swap src/dst ports, set length, zero checksum
    let udp_off = ihl;
    resp[udp_off] = request[ihl + 2];     // src port = old dst port
    resp[udp_off + 1] = request[ihl + 3];
    resp[udp_off + 2] = request[ihl];     // dst port = old src port
    resp[udp_off + 3] = request[ihl + 1];
    let udp_len = (8 + dns_payload.len()) as u16;
    resp[udp_off + 4] = (udp_len >> 8) as u8;
    resp[udp_off + 5] = (udp_len & 0xFF) as u8;
    // UDP checksum = 0 (optional for IPv4)
    resp[udp_off + 6] = 0;
    resp[udp_off + 7] = 0;

    // DNS payload
    let payload_off = udp_off + 8;
    resp[payload_off..payload_off + dns_payload.len()].copy_from_slice(dns_payload);

    match tun.lock().send(&resp) {
        Ok(n) => {
            traffic.bytes_received.fetch_add(n as u64, Ordering::Relaxed);
            traffic.packets_received.fetch_add(1, Ordering::Relaxed);
            true
        }
        Err(e) => {
            if e.kind() != std::io::ErrorKind::WouldBlock {
                android_log(&format!("DNS->TUN write error: {}", e));
            }
            false
        }
    }
}

/// Reverse NAT: rewrite the destination IP address back from the
/// server-assigned IP to the TUN IP for incoming packets on the
/// recvConn → TUN path. The Android kernel expects packets addressed
/// to the TUN IP (10.0.0.2), not the server-assigned IP.
fn nat_rewrite_dest_ipv4(packet: &mut [u8], from: [u8; 4], to: [u8; 4]) {
    if packet.len() < 20 {
        return;
    }

    let version_ihl = packet[0];
    if (version_ihl >> 4) != 4 {
        return;
    }

    let ihl = (version_ihl & 0x0F) as usize * 4;
    if packet.len() < ihl {
        return;
    }

    let total_length = u16::from_be_bytes([packet[2], packet[3]]) as usize;
    if total_length > packet.len() {
        return;
    }

    let dst = &packet[16..20];
    let actual_dst: [u8; 4] = [packet[16], packet[17], packet[18], packet[19]];

    if dst != &from {
        return;
    }

    // Rewrite destination IP
    packet[16] = to[0];
    packet[17] = to[1];
    packet[18] = to[2];
    packet[19] = to[3];

    // Recalculate IPv4 header checksum
    packet[10] = 0;
    packet[11] = 0;
    let mut sum: u32 = 0;
    for i in (0..ihl).step_by(2) {
        if i + 1 < ihl {
            sum += u16::from_be_bytes([packet[i], packet[i + 1]]) as u32;
        }
    }
    while sum > 0xFFFF {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }
    let checksum = !(sum as u16);
    packet[10] = (checksum >> 8) as u8;
    packet[11] = (checksum & 0xFF) as u8;

    // Recalculate TCP/UDP checksum (covers pseudo-header with dst IP)
    let protocol = packet[9];
    if protocol != 6 && protocol != 17 {
        return;
    }

    let payload_offset = ihl;
    if total_length < payload_offset + 8 || total_length > packet.len() {
        return;
    }

    let transport_len = total_length - payload_offset;
    let transport = &mut packet[payload_offset..total_length];

    let old_checksum: u16;
    let csum_offset: usize;
    if protocol == 6 {
        if transport_len < 18 {
            return;
        }
        old_checksum = u16::from_be_bytes([transport[16], transport[17]]);
        csum_offset = 16;
    } else {
        if transport_len < 8 {
            return;
        }
        old_checksum = u16::from_be_bytes([transport[6], transport[7]]);
        csum_offset = 6;
    }

    let old_dst = u16::from_be_bytes([actual_dst[0], actual_dst[1]]) as u32
        + u16::from_be_bytes([actual_dst[2], actual_dst[3]]) as u32;
    let new_dst = u16::from_be_bytes([to[0], to[1]]) as u32
        + u16::from_be_bytes([to[2], to[3]]) as u32;

    let delta = new_dst.wrapping_sub(old_dst);

    let mut csum = (!old_checksum) as u32;
    csum = csum.wrapping_add(delta);
    while csum > 0xFFFF {
        csum = (csum & 0xFFFF) + (csum >> 16);
    }
    let new_checksum = !(csum as u16);

    let final_checksum = if protocol == 17 && new_checksum == 0 {
        0xFFFFu16
    } else {
        new_checksum
    };

    transport[csum_offset] = (final_checksum >> 8) as u8;
    transport[csum_offset + 1] = (final_checksum & 0xFF) as u8;
}