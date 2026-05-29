use std::env;
use std::path::PathBuf;
use std::process::Command;

/// Find a Visual Studio tool executable. Searches common VS installation paths.
fn find_vs_tool(tool: &str) -> Option<String> {
    let vs_paths = &[
        "D:\\VisualStudio\\2026\\Community\\VC\\Tools\\MSVC",
        "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Tools\\MSVC",
        "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Community\\VC\\Tools\\MSVC",
        "C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional\\VC\\Tools\\MSVC",
        "C:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise\\VC\\Tools\\MSVC",
    ];

    for vs_path in vs_paths {
        let base = PathBuf::from(vs_path);
        if base.exists() {
            if let Ok(entries) = std::fs::read_dir(&base) {
                let mut versions: Vec<_> = entries
                    .filter_map(|e| e.ok())
                    .filter(|e| e.path().is_dir())
                    .collect();
                versions.sort_by(|a, b| b.file_name().cmp(&a.file_name()));
                for entry in versions {
                    let tool_path = entry.path().join("bin").join("Hostx64").join("x64").join(tool);
                    if tool_path.exists() {
                        return Some(tool_path.to_str().unwrap().to_string());
                    }
                }
            }
        }
    }
    None
}

/// Map Rust target triple to Go GOARCH
fn go_arch_from_target(target: &str) -> &str {
    if target.starts_with("aarch64") {
        "arm64"
    } else if target.starts_with("armv7") {
        "arm"
    } else if target.starts_with("arm") {
        "arm"
    } else if target.starts_with("x86_64") {
        "amd64"
    } else if target.starts_with("i686") || target.starts_with("i586") {
        "386"
    } else {
        "amd64" // fallback
    }
}

/// Set up Go cross-compilation environment variables for Android targets
fn setup_android_go_env(cmd: &mut Command, target: &str, go_arch: &str) {
    cmd.env("GOOS", "android").env("GOARCH", go_arch);

    eprintln!("[DEBUG] ===== setup_android_go_env: target={target}, go_arch={go_arch} =====");
    eprintln!("[DEBUG] ANDROID_NDK_HOME={:?}", env::var("ANDROID_NDK_HOME").ok());
    eprintln!("[DEBUG] ANDROID_HOME={:?}", env::var("ANDROID_HOME").ok());
    eprintln!("[DEBUG] ANDROID_SDK_ROOT={:?}", env::var("ANDROID_SDK_ROOT").ok());
    eprintln!("[DEBUG] CC={:?}", env::var("CC").ok());

    if go_arch == "arm" {
        cmd.env("GOARM", "7");
    }

    // Strategy 1: cargo-ndk / cargokit sets CC_<target>
    // NOTE: cargokit sets this to generic clang.exe (without --target=),
    // which is NOT suitable for Go CGo. We must replace it with the
    // target-specific wrapper (e.g. aarch64-linux-android35-clang.cmd).
    let cc_var = format!("CC_{}", target);
    eprintln!("[DEBUG] S1: checking env var '{cc_var}'");
    match env::var(&cc_var) {
        Ok(cc) if !cc.is_empty() => {
            eprintln!("[DEBUG] S1: cargokit CC={cc}");
            // Try to find the NDK target-specific clang wrapper in the same bin dir
            if let Some(bin_dir) = PathBuf::from(&cc).parent() {
                if let Some(target_cc) = find_clang_in_bin(&bin_dir.to_path_buf(), go_arch) {
                    eprintln!("[DEBUG] S1: -> using target-specific {target_cc}");
                    cmd.env("CC", &target_cc);
                    return;
                }
            }
            // Fallback: use generic clang and hope Go sets --target= correctly
            eprintln!("[DEBUG] S1: WARNING no target-specific wrapper found, falling back to generic {cc}");
            cmd.env("CC", &cc);
            return;
        }
        Ok(_) => eprintln!("[DEBUG] S1: {cc_var} is empty"),
        Err(_) => eprintln!("[DEBUG] S1: {cc_var} not set"),
    }

    // Strategy 2: check CC env var (but reject non-Android toolchains)
    match env::var("CC") {
        Ok(cc) if !cc.is_empty() => {
            let cc_lower = cc.to_lowercase();
            if cc_lower.contains("mingw") || cc_lower.contains("msvc") || cc_lower.contains("cl.exe") {
                eprintln!("[DEBUG] S2: CC={cc} REJECTED (non-Android toolchain)");
            } else {
                eprintln!("[DEBUG] S2: using CC={cc}");
                cmd.env("CC", &cc);
                return;
            }
        }
        _ => eprintln!("[DEBUG] S2: CC not set or empty"),
    }

    // Strategy 3: ANDROID_NDK_HOME env var
    let ndk_home = env::var("ANDROID_NDK_HOME").unwrap_or_default();
    eprintln!("[DEBUG] S3: trying ANDROID_NDK_HOME='{ndk_home}'");
    if !ndk_home.is_empty() {
        match find_ndk_clang(&ndk_home, go_arch) {
            Some(cc) => {
                eprintln!("[DEBUG] S3: FOUND clang='{cc}'");
                cmd.env("CC", &cc);
                return;
            }
            None => eprintln!("[DEBUG] S3: find_ndk_clang returned None"),
        }
    }

    // Strategy 4: ANDROID_HOME / ANDROID_SDK_ROOT → ndk/
    let sdk_roots: Vec<Option<String>> = vec![
        env::var("ANDROID_HOME").ok(),
        env::var("ANDROID_SDK_ROOT").ok(),
        env::var("LOCALAPPDATA").ok().map(|p| format!("{}/Android/Sdk", p)),
        env::var("USERPROFILE").ok().map(|p| format!("{}/AppData/Local/Android/Sdk", p)),
    ];

    for sdk_root in sdk_roots.iter().flatten() {
        let ndk_dir = PathBuf::from(sdk_root).join("ndk");
        eprintln!("[DEBUG] S4: checking ndk_dir={}", ndk_dir.display());
        if ndk_dir.exists() {
            eprintln!("[DEBUG] S4: ndk_dir EXISTS, searching...");
            match find_ndk_clang(&ndk_dir.to_string_lossy(), go_arch) {
                Some(cc) => {
                    eprintln!("[DEBUG] S4: FOUND clang='{cc}'");
                    cmd.env("CC", &cc);
                    return;
                }
                None => eprintln!("[DEBUG] S4: find_ndk_clang returned None"),
            }
        } else {
            eprintln!("[DEBUG] S4: ndk_dir does NOT exist");
        }
    }

    // No NDK found — panic immediately to avoid Go using wrong compiler (e.g., MinGW)
    panic!(
        "Cannot find Android NDK C compiler for Go cross-compilation.\n\
         Target: {target}\n\
         \n\
         Please set one of:\n\
         1. ANDROID_NDK_HOME=/path/to/ndk/<version>\n\
         2. ANDROID_HOME=/path/to/Android/Sdk (NDK must be installed via SDK Manager)\n\
         3. Use cargo-ndk which sets CC_{target} automatically\n\
         \n\
         The NDK directory structure should be: <ndk>/toolchains/llvm/prebuilt/<host>/bin/\n\
         Current CC env: {:?}",
        env::var("CC").ok()
    );
}

/// Find the NDK clang compiler for Go cross-compilation.
/// Handles both NDK root dir (containing version subdirs) and version dir (directly containing toolchains).
fn find_ndk_clang(base_path: &str, go_arch: &str) -> Option<String> {
    let base = PathBuf::from(base_path);
    if !base.exists() {
        return None;
    }

    // First, check if this path directly contains toolchains/ (i.e., it's already a version dir)
    let toolchains_dir = base.join("toolchains");
    if toolchains_dir.exists() {
        eprintln!("[DEBUG] find_ndk_clang: '{base_path}' is a version dir (has toolchains/)");
        return find_clang_in_toolchains(&base, go_arch);
    }

    // Otherwise, treat as NDK root: iterate version subdirectories
    eprintln!("[DEBUG] find_ndk_clang: '{base_path}' is an NDK root, searching version dirs...");
    let mut versions: Vec<String> = Vec::new();
    if let Ok(entries) = std::fs::read_dir(&base) {
        for entry in entries.filter_map(|e| e.ok()) {
            if entry.file_type().map(|t| t.is_dir()).unwrap_or(false) {
                let name = entry.file_name().to_string_lossy().to_string();
                // Version dirs are numeric like "29.0.14206865"
                if name.chars().next().map_or(false, |c| c.is_ascii_digit()) {
                    versions.push(name);
                }
            }
        }
    }
    versions.sort_by(|a, b| b.cmp(a));
    eprintln!("[DEBUG] find_ndk_clang: found version dirs: {versions:?}");

    for ver in &versions {
        let ver_dir = base.join(ver);
        if let Some(cc) = find_clang_in_toolchains(&ver_dir, go_arch) {
            return Some(cc);
        }
    }

    None
}

/// Search toolchains/llvm/prebuilt/<host>/bin/ for target-specific clang
fn find_clang_in_toolchains(ndk_version_dir: &PathBuf, go_arch: &str) -> Option<String> {
    let host_tags = if cfg!(target_os = "windows") {
        vec!["windows-x86_64", "windows"]
    } else if cfg!(target_os = "macos") {
        vec!["darwin-x86_64"]
    } else {
        vec!["linux-x86_64"]
    };

    for host_tag in &host_tags {
        let bin_dir = ndk_version_dir
            .join("toolchains")
            .join("llvm")
            .join("prebuilt")
            .join(host_tag)
            .join("bin");
        if bin_dir.exists() {
            if let Some(clang) = find_clang_in_bin(&bin_dir, go_arch) {
                return Some(clang);
            }
        }
    }

    None
}

fn find_clang_in_bin(bin_dir: &PathBuf, go_arch: &str) -> Option<String> {
    // Determine the highest available API level
    let mut best_clang: Option<String> = None;
    let mut best_api = 0u32;

    if let Ok(entries) = std::fs::read_dir(bin_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let name = entry.file_name().to_string_lossy().to_string();
            // Match patterns like "aarch64-linux-android21-clang" or "aarch64-linux-android33-clang.cmd"
            let arch_prefix = match go_arch {
                "arm64" => "aarch64-linux-android",
                "arm" => "armv7a-linux-androideabi",
                "amd64" => "x86_64-linux-android",
                "386" => "i686-linux-android",
                _ => "aarch64-linux-android",
            };

            if name.starts_with(arch_prefix) && (name.ends_with("-clang") || name.ends_with("-clang.cmd")) {
                // Extract API level
                let rest = &name[arch_prefix.len()..];
                if let Some(api_str) = rest.split('-').next() {
                    if let Ok(api) = api_str.parse::<u32>() {
                        if api > best_api {
                            best_api = api;
                            best_clang = Some(entry.path().to_string_lossy().to_string());
                        }
                    }
                }
            }
        }
    }

    best_clang
}

/// Set up Go cross-compilation environment variables for iOS targets
fn setup_ios_go_env(cmd: &mut Command, target: &str, go_arch: &str) {
    cmd.env("GOOS", "ios").env("GOARCH", go_arch);

    // iOS cross-compilation requires macOS with Xcode
    if !cfg!(target_os = "macos") {
        eprintln!(
            "WARNING: Building Go for iOS target '{}' on a non-macOS host. \
             This requires Xcode and will likely fail.",
            target
        );
        return;
    }

    let sdk = if target.contains("sim") {
        "iphonesimulator"
    } else {
        "iphoneos"
    };

    // Find clang via xcrun
    if let Ok(output) = Command::new("xcrun")
        .args(["--sdk", sdk, "--find", "clang"])
        .output()
    {
        let cc_path = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !cc_path.is_empty() {
            cmd.env("CC", &cc_path);
        }
    }

    // Set SDK sysroot
    if let Ok(output) = Command::new("xcrun")
        .args(["--sdk", sdk, "--show-sdk-path"])
        .output()
    {
        let sdk_path = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !sdk_path.is_empty() {
            cmd.env(
                "CGO_CFLAGS",
                format!("-isysroot {} -arch {}", sdk_path, go_arch),
            );
        }
    }

    // iOS requires CGO_LDFLAGS for bitcode (optional)
    cmd.env("CGO_LDFLAGS", format!("-arch {}", go_arch));
}

/// Map Rust Rust target triple to Android ABI subdirectory for jniLibs
fn android_abi_from_target(target: &str) -> &str {
    if target.starts_with("aarch64") {
        "arm64-v8a"
    } else if target.starts_with("armv7") {
        "armeabi-v7a"
    } else if target.starts_with("x86_64") {
        "x86_64"
    } else if target.starts_with("i686") || target.starts_with("i586") {
        "x86"
    } else {
        "arm64-v8a" // fallback
    }
}

fn main() {
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let go_dir = PathBuf::from("go");
    assert!(go_dir.exists(), "go directory not found");

    let lib_name = "tunnel";
    let target = env::var("TARGET").unwrap_or_default();

    // Determine target platform. If TARGET is not set (unusual), fall back to host detection.
    let is_windows_target = if target.is_empty() {
        cfg!(target_os = "windows")
    } else {
        target.contains("windows")
    };
    let is_android_target = target.contains("android");
    let is_ios_target = target.contains("apple-ios");

    if is_windows_target {
        // ── Windows target: build c-shared DLL ──
        // c-archive on Windows has MSVC .pdata incompatibility (LNK1223).
        let dll_path = out_dir.join(format!("{}.dll", lib_name));

        let status = Command::new("go")
            .current_dir(&go_dir)
            .env("CGO_ENABLED", "1")
            .args(&["build", "-buildmode=c-shared", "-o"])
            .arg(&dll_path)
            .status()
            .expect("failed to execute go build");

        if !status.success() {
            panic!("go build failed");
        }

        // Remove the generated .h file, we don't need it
        let _ = std::fs::remove_file(out_dir.join(format!("{}.h", lib_name)));

        // Generate .def file with known exports from tunnel.go (//export annotations)
        let def_content = "LIBRARY tunnel\nEXPORTS\n\
            EC_New\n\
            EC_SetSmsCode\n\
            EC_Free\n\
            EC_LoginStart\n\
            EC_LoginPassword\n\
            EC_LoginSMS\n\
            EC_LoginTOTP\n\
            EC_GetToken\n\
            EC_GetResources\n\
            EC_GetIP\n\
            EC_GetAssignedIP\n\
            EC_OpenDataChannels\n\
            EC_ReadRecv\n\
            EC_WriteSend\n\
            EC_ReadSend\n\
            EC_GetDNSServer\n\
            EC_GetDnsData\n\
            EC_GetDnsRoutes\n\
            EC_IsConnected\n";
        let def_path = out_dir.join(format!("{}.def", lib_name));
        std::fs::write(&def_path, def_content).expect("failed to write .def file");

        let lib_exe = find_vs_tool("lib.exe").unwrap_or_else(|| "lib.exe".to_string());

        let lib_path = out_dir.join(format!("{}.lib", lib_name));
        let lib_status = Command::new(&lib_exe)
            .arg(format!("/def:{}", def_path.to_str().unwrap()))
            .arg(format!("/out:{}", lib_path.to_str().unwrap()))
            .arg("/machine:x64")
            .status()
            .expect("failed to run lib.exe");

        if !lib_status.success() {
            panic!("lib.exe failed to generate import library");
        }

        println!("cargo:rustc-link-search=native={}", out_dir.display());
        println!("cargo:rustc-link-lib={}", lib_name);

        // Copy tunnel.dll alongside rust_lib_punklorde.dll for runtime loading
        let target_dir = out_dir
            .parent()
            .and_then(|p| p.parent())
            .and_then(|p| p.parent());
        if let Some(target_dir) = target_dir {
            let dest_dll = target_dir.join(format!("{}.dll", lib_name));
            if dest_dll != dll_path {
                std::fs::copy(&dll_path, &dest_dll)
                    .unwrap_or_else(|e| panic!("failed to copy tunnel.dll to {}: {}", dest_dll.display(), e));
                println!("cargo:warning=Copied tunnel.dll to {}", dest_dll.display());
            }
        }
    } else if is_android_target {
        // ── Android target: build c-shared .so (c-archive unsupported on Android) ──
        let go_arch = go_arch_from_target(&target);
        let so_lib = out_dir.join(format!("lib{}.so", lib_name));

        let mut cmd = Command::new("go");
        cmd.current_dir(&go_dir)
            .env("CGO_ENABLED", "1")
            .args(&["build", "-buildmode=c-shared", "-o"])
            .arg(&so_lib);

        setup_android_go_env(&mut cmd, &target, go_arch);

        let status = cmd.status().expect("failed to execute go build");
        if !status.success() {
            panic!(
                "go build failed for Android target '{}'.\n\
                 HINT: Set ANDROID_NDK_HOME or use cargo-ndk.",
                target
            );
        }

        // Remove generated .h, not needed
        let _ = std::fs::remove_file(out_dir.join(format!("{}.h", lib_name)));

        // Dynamic link against the Go .so
        println!("cargo:rustc-link-search=native={}", out_dir.display());
        println!("cargo:rustc-link-lib=dylib={}", lib_name);

        // Copy libtunnel.so to target dir so Rust can link against it
        let target_dir = out_dir
            .parent()          // .../<hash>/
            .and_then(|p| p.parent())  // .../build/
            .and_then(|p| p.parent()); // .../<profile>/
        // target_dir = build/rust_lib_punklorde/build/<target>/<profile>/
        if let Some(target_dir) = target_dir {
            let dest_so = target_dir.join(format!("lib{}.so", lib_name));
            if dest_so != so_lib {
                std::fs::copy(&so_lib, &dest_so)
                    .unwrap_or_else(|e| panic!("failed to copy libtunnel.so to {}: {}", dest_so.display(), e));
                println!("cargo:warning=Copied libtunnel.so to {}", dest_so.display());
            }

            // Navigate up to project build dir: build/rust_lib_punklorde/
            // then copy to cargokit's jniLibs/<profile>/<abi>/ which is what cargokit
            // actually registers as the jniLibs source directory (see plugin.gradle).
            if let Some(pbd) = target_dir
                .parent()          // .../<target>/
                .and_then(|p| p.parent())  // .../build/
                .and_then(|p| p.parent())  // build/rust_lib_punklorde/
            {
                let profile = if cfg!(debug_assertions) { "debug" } else { "release" };
                let abi = android_abi_from_target(&target);
                let cargokit_jni = pbd.join("jniLibs").join(profile).join(abi);
                std::fs::create_dir_all(&cargokit_jni)
                    .unwrap_or_else(|e| panic!("failed to create cargokit jniLibs dir {}: {}", cargokit_jni.display(), e));
                let jni_so = cargokit_jni.join(format!("lib{}.so", lib_name));
                std::fs::copy(&so_lib, &jni_so)
                    .unwrap_or_else(|e| panic!("failed to copy libtunnel.so to {}: {}", jni_so.display(), e));
                println!("cargo:warning=Copied libtunnel.so to cargokit jniLibs: {}", jni_so.display());
            }
        }

        // Also copy to android/app/src/main/jniLibs/<abi>/ as fallback
        let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
        let abi = android_abi_from_target(&target);
        let jni_libs_dir = manifest_dir.join("../android/app/src/main/jniLibs").join(abi);
        std::fs::create_dir_all(&jni_libs_dir)
            .unwrap_or_else(|e| panic!("failed to create jniLibs dir {}: {}", jni_libs_dir.display(), e));
        let jni_so = jni_libs_dir.join(format!("lib{}.so", lib_name));
        std::fs::copy(&so_lib, &jni_so)
            .unwrap_or_else(|e| panic!("failed to copy libtunnel.so to {}: {}", jni_so.display(), e));
        println!("cargo:warning=Copied libtunnel.so to jniLibs/{}", jni_so.display());
    } else {
        // ── Other targets (macOS, Linux, iOS): build c-archive static library ──
        let static_lib = out_dir.join(format!("lib{}.a", lib_name));

        let go_arch = go_arch_from_target(&target);

        let mut cmd = Command::new("go");
        cmd.current_dir(&go_dir)
            .env("CGO_ENABLED", "1")
            .args(&["build", "-buildmode=c-archive", "-o"])
            .arg(&static_lib);

        if is_android_target {
            setup_android_go_env(&mut cmd, &target, go_arch);
        } else if is_ios_target {
            setup_ios_go_env(&mut cmd, &target, go_arch);
        }
        // For macOS/Linux host targets, use the system Go compiler (no extra env)

        let status = cmd.status().expect("failed to execute go build");
        if !status.success() {
            panic!(
                "go build failed for target '{}'.\n\
                 HINT: For Android, set ANDROID_NDK_HOME or use cargo-ndk.\n\
                 HINT: For iOS, build on macOS with Xcode installed.",
                target
            );
        }

        println!("cargo:rustc-link-search=native={}", out_dir.display());
        println!("cargo:rustc-link-lib=static={}", lib_name);

        // Link platform-specific system libraries
        if is_ios_target || target.contains("apple-darwin") {
            println!("cargo:rustc-link-lib=framework=SystemConfiguration");
            println!("cargo:rustc-link-lib=framework=CoreFoundation");
            println!("cargo:rustc-link-lib=framework=Security");
        } else if target.contains("linux") {
            println!("cargo:rustc-link-lib=dl");
            println!("cargo:rustc-link-lib=pthread");
            println!("cargo:rustc-link-lib=resolv");
            println!("cargo:rustc-link-lib=m");
        }
        // Android: no extra system libs needed (Bionic libc includes net/dns)
    }

    println!("cargo:rerun-if-changed=go");
    println!("cargo:rerun-if-env-changed=ANDROID_NDK_HOME");
    println!("cargo:rerun-if-env-changed=ANDROID_PLATFORM");
}