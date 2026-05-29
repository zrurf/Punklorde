//! Sangfor VPN API - FRB bridge layer
//!
//! Exposes opaque string handles to Flutter for VPN lifecycle management.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use anyhow::Result;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use uuid::Uuid;

use crate::frb_generated::StreamSink;
use crate::services::sangfor::SangforVpnService;
pub use crate::services::sangfor::{VpnConfig, VpnState};

// fdsan: Go runtime manages its own file descriptors and doesn't tag them
// for Android's fdsan. When Go closes a network connection (e.g. TLS conn),
// fdsan sees an unowned fd and aborts. Set fdsan to warn-only.
#[cfg(target_os = "android")]
extern "C" {
    fn android_fdsan_set_error_level(level: u64) -> u64;
}
#[cfg(target_os = "android")]
const ANDROID_FDSAN_ERROR_LEVEL_WARN: u64 = 1;

#[cfg(target_os = "android")]
static FDSAN_INIT: std::sync::Once = std::sync::Once::new();

/// Workaround: Go runtime fds don't carry Android fdsan tags.
/// Set fdsan to warn-only so Go's fd close doesn't SIGABRT.
#[cfg(target_os = "android")]
fn init_fdsan() {
    FDSAN_INIT.call_once(|| unsafe {
        android_fdsan_set_error_level(ANDROID_FDSAN_ERROR_LEVEL_WARN);
    });
}

// Global VPN service storage
type VpnMap = Arc<Mutex<HashMap<String, Arc<Mutex<SangforVpnService>>>>>;

lazy_static! {
    static ref VPN_SERVICES: VpnMap = Arc::new(Mutex::new(HashMap::new()));
}

/// Create a new VPN service, returns opaque handle ID
#[frb(sync)]
pub fn create_vpn(config: VpnConfig) -> Result<String, String> {
    #[cfg(target_os = "android")]
    init_fdsan();
    let service = SangforVpnService::new(config);
    let handle_id = Uuid::new_v4().to_string();
    let mut map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    map.insert(handle_id.clone(), Arc::new(Mutex::new(service)));
    Ok(handle_id)
}

/// Start VPN connection
#[frb(sync)]
pub fn connect_vpn(handle_id: String) -> Result<(), String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let mut service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.connect()
}

/// Phase 1: Authenticate and retrieve the server-assigned IP.
///
/// This blocks the calling thread during network I/O (typically 2-5 seconds).
/// Returns the server-assigned IP string on success.
/// Returns Err("SMS_REQUIRED") or Err("TOTP_REQUIRED") if 2FA is needed.
/// After 2FA, call `continue_vpn_auth_and_get_ip()` to finish auth and get the IP.
///
/// Use the returned IP to configure the TUN device (Android VpnService).
/// Then call `open_vpn_channels_and_relay()` to start the VPN data relay.
#[frb(sync)]
pub fn authenticate_vpn_and_get_ip(handle_id: String) -> Result<String, String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.authenticate_and_get_ip()
}

/// Continue authentication after 2FA code submission.
///
/// Call this after the user provides their SMS/TOTP code.
/// Returns the server-assigned IP string on success.
/// Then call `open_vpn_channels_and_relay()` to start the VPN data relay.
#[frb(sync)]
pub fn continue_vpn_auth_and_get_ip(handle_id: String, code: String) -> Result<String, String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.continue_auth_after_2fa_and_get_ip(&code)
}

/// Phase 2: Open data channels and start TUN relay.
///
/// Must be called after:
/// 1. `authenticate_vpn_and_get_ip()` (or `continue_vpn_auth_and_get_ip()`) succeeded
/// 2. On Android: `set_tun_fd()` was called with the TUN fd
///
/// This method spawns a background thread for the relay and returns immediately.
#[frb(sync)]
pub fn open_vpn_channels_and_relay(handle_id: String) -> Result<(), String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.open_channels_and_relay()
}

/// Get the server-assigned IP (if authentication has completed).
/// Returns None if the IP has not been retrieved yet.
#[frb(sync)]
pub fn get_vpn_assigned_ip(handle_id: String) -> Option<String> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    service.get_assigned_ip()
}

/// Get the campus DNS server parsed from VPN resources.
/// Returns None if the DNS has not been retrieved yet (before auth completes).
#[frb(sync)]
pub fn get_vpn_dns_server(handle_id: String) -> Option<String> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    service.get_dns_server()
}

/// Get DNS route IPs (unique mapped IPs from <Dns data>),
/// comma-separated, for adding as /32 VPN routes.
#[frb(sync)]
pub fn get_vpn_dns_routes(handle_id: String) -> Option<String> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    service.get_dns_routes()
}

/// Submit 2FA code (SMS or TOTP)
#[frb(sync)]
pub fn submit_2fa(handle_id: String, code: String) -> Result<(), String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.submit_2fa(&code)
}

/// Disconnect VPN
#[frb(sync)]
pub fn disconnect_vpn(handle_id: String) {
    if let Ok(map) = VPN_SERVICES.lock() {
        if let Some(service_arc) = map.get(&handle_id) {
            if let Ok(mut service) = service_arc.lock() {
                service.disconnect();
            }
        }
    }
}

/// On Android, set the TUN file descriptor from VpnService.establish().
/// Must be called before connect_vpn() on Android targets.
/// On non-Android targets, this is a no-op (fd is ignored).
#[frb(sync)]
pub fn set_tun_fd(handle_id: String, fd: i32) -> Result<(), String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.set_tun_fd(fd);
    Ok(())
}

/// Get current VPN state
#[frb(sync)]
pub fn get_vpn_state(handle_id: String) -> Option<VpnState> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    Some(service.get_state())
}

/// Get VPN config
#[frb(sync)]
pub fn get_vpn_config(handle_id: String) -> Option<VpnConfig> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    Some(service.get_config())
}

/// Check if VPN is running
#[frb(sync)]
pub fn is_vpn_running(handle_id: String) -> Option<bool> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    Some(service.is_running())
}

/// Get VPN traffic statistics
#[frb(sync)]
pub fn get_vpn_traffic_stats(
    handle_id: String,
) -> Option<crate::services::sangfor::VpnTrafficStats> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    Some(service.get_traffic_stats())
}

/// Get the last error message from VPN service
#[frb(sync)]
pub fn get_vpn_last_error(handle_id: String) -> Option<String> {
    let map = VPN_SERVICES.lock().ok()?;
    let service_arc = map.get(&handle_id)?;
    let service = service_arc.lock().ok()?;
    service.get_last_error()
}

/// Subscribe to VPN state changes
#[frb(stream_dart_await)]
pub fn subscribe_vpn_state(
    handle_id: String,
    sink: StreamSink<VpnState>,
) -> Result<(), String> {
    let map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    let service_arc = map.get(&handle_id).ok_or("VPN service not found")?;
    let mut service = service_arc.lock().map_err(|_| "Mutex poisoned".to_string())?;
    service.set_stream_sink(sink);
    Ok(())
}

/// Dispose VPN service
#[frb(sync)]
pub fn dispose_vpn(handle_id: String) -> Result<(), String> {
    let mut map = VPN_SERVICES.lock().map_err(|_| "Mutex poisoned".to_string())?;
    if let Some(service_arc) = map.remove(&handle_id) {
        if let Ok(mut service) = service_arc.lock() {
            service.disconnect();
        }
    }
    Ok(())
}