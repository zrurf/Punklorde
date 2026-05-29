//! CGo FFI bindings for the Go tunnel library

use std::ffi::{c_char, c_int, c_void, CStr, CString};

extern "C" {
    pub fn EC_New(
        server: *const c_char,
        username: *const c_char,
        password: *const c_char,
        totp_secret: *const c_char,
    ) -> c_int;

    pub fn EC_Free(id: c_int);

    pub fn EC_SetSmsCode(id: c_int, code: *const c_char);

    pub fn EC_LoginStart(id: c_int) -> *mut c_char;
    pub fn EC_LoginPassword(id: c_int) -> *mut c_char;
    pub fn EC_LoginSMS(id: c_int) -> *mut c_char;
    pub fn EC_LoginTOTP(id: c_int) -> *mut c_char;
    pub fn EC_GetToken(id: c_int) -> *mut c_char;
    pub fn EC_GetResources(id: c_int) -> *mut c_char;
    pub fn EC_GetIP(id: c_int) -> *mut c_char;
    pub fn EC_GetAssignedIP(id: c_int) -> *mut c_char;
    pub fn EC_OpenDataChannels(id: c_int) -> *mut c_char;
    pub fn EC_GetDNSServer(id: c_int) -> *mut c_char;
    pub fn EC_GetDnsData(id: c_int) -> *mut c_char;
    pub fn EC_GetDnsRoutes(id: c_int) -> *mut c_char;
    pub fn EC_IsConnected(id: c_int) -> c_int;

    pub fn EC_ReadRecv(id: c_int, buf: *mut c_void, buf_len: c_int) -> c_int;
    pub fn EC_ReadSend(id: c_int, buf: *mut c_void, buf_len: c_int) -> c_int;
    pub fn EC_WriteSend(id: c_int, buf: *const c_void, buf_len: c_int) -> c_int;
}

/// Helper to read a nullable C string from FFI and free it
unsafe fn read_c_string(ptr: *mut c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    let result = CStr::from_ptr(ptr).to_string_lossy().into_owned();
    // The Go side allocates with C.CString, we must free with C free
    unsafe { libc::free(ptr as *mut libc::c_void) };
    Some(result)
}

/// Helper to convert &str to CString
fn to_c_str(s: &str) -> CString {
    CString::new(s).unwrap_or_else(|_| CString::new("").unwrap())
}

// ===================== Safe Wrapper =====================

pub struct GoVpnClient {
    pub id: c_int,
}

impl GoVpnClient {
    pub fn new(server: &str, username: &str, password: &str, totp_secret: &str) -> Self {
        let s = to_c_str(server);
        let u = to_c_str(username);
        let p = to_c_str(password);
        let t = to_c_str(totp_secret);
        let id = unsafe { EC_New(s.as_ptr(), u.as_ptr(), p.as_ptr(), t.as_ptr()) };
        GoVpnClient { id }
    }

    pub fn set_sms_code(&mut self, code: &str) {
        let c = to_c_str(code);
        unsafe { EC_SetSmsCode(self.id, c.as_ptr()) }
    }

    pub fn login_start(&mut self) -> Result<(), String> {
        let result = unsafe { EC_LoginStart(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from login_start".to_string()),
            None => Ok(()),
        }
    }

    pub fn login_password(&mut self) -> Result<(), String> {
        let result = unsafe { EC_LoginPassword(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from login_password".to_string()),
            None => Ok(()),
        }
    }

    pub fn login_sms(&mut self) -> Result<(), String> {
        let result = unsafe { EC_LoginSMS(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from login_sms".to_string()),
            None => Ok(()),
        }
    }

    pub fn login_totp(&mut self) -> Result<(), String> {
        let result = unsafe { EC_LoginTOTP(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from login_totp".to_string()),
            None => Ok(()),
        }
    }

    pub fn get_token(&mut self) -> Result<(), String> {
        let result = unsafe { EC_GetToken(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from get_token".to_string()),
            None => Ok(()),
        }
    }

    pub fn get_resources(&mut self) -> Result<String, String> {
        let result = unsafe { EC_GetResources(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(xml) => Ok(xml),
            None => Err("no resources returned".to_string()),
        }
    }

    pub fn get_ip(&mut self) -> Result<(), String> {
        let result = unsafe { EC_GetIP(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from get_ip".to_string()),
            None => Ok(()),
        }
    }

    pub fn open_data_channels(&mut self) -> Result<(), String> {
        let result = unsafe { EC_OpenDataChannels(self.id) };
        match unsafe { read_c_string(result) } {
            Some(msg) if msg.starts_with("ERR:") => Err(msg[4..].to_string()),
            Some(_) => Err("unexpected response from open_data_channels".to_string()),
            None => Ok(()),
        }
    }

    pub fn get_assigned_ip(&self) -> Option<String> {
        let result = unsafe { EC_GetAssignedIP(self.id) };
        let s = unsafe { read_c_string(result) };
        s.filter(|s| !s.is_empty())
    }

    pub fn get_dns_server(&self) -> Option<String> {
        let result = unsafe { EC_GetDNSServer(self.id) };
        let s = unsafe { read_c_string(result) };
        s.filter(|s| !s.is_empty())
    }

    pub fn get_dns_data(&self) -> Option<String> {
        let result = unsafe { EC_GetDnsData(self.id) };
        let s = unsafe { read_c_string(result) };
        s.filter(|s| !s.is_empty())
    }

    pub fn get_dns_routes(&self) -> Option<String> {
        let result = unsafe { EC_GetDnsRoutes(self.id) };
        let s = unsafe { read_c_string(result) };
        s.filter(|s| !s.is_empty())
    }

    pub fn is_connected(&self) -> bool {
        unsafe { EC_IsConnected(self.id) != 0 }
    }

    pub fn read_recv(&mut self, buf: &mut [u8]) -> Result<usize, ()> {
        let n = unsafe { EC_ReadRecv(self.id, buf.as_mut_ptr() as *mut c_void, buf.len() as c_int) };
        if n < 0 {
            Err(())
        } else {
            Ok(n as usize)
        }
    }

    pub fn write_send(&mut self, buf: &[u8]) -> Result<usize, ()> {
        let n = unsafe { EC_WriteSend(self.id, buf.as_ptr() as *const c_void, buf.len() as c_int) };
        if n < 0 {
            Err(())
        } else {
            Ok(n as usize)
        }
    }
}

impl Drop for GoVpnClient {
    fn drop(&mut self) {
        unsafe { EC_Free(self.id) }
    }
}