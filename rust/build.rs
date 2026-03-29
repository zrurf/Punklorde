use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let go_dir = PathBuf::from("go");
    assert!(go_dir.exists(), "go directory not found");

    let lib_name = "tunnel";
    let static_lib = out_dir.join(format!("lib{}.a", lib_name));

    // 构建 Go 静态库
    let status = Command::new("go")
        .current_dir(&go_dir)
        .args(&["build", "-buildmode=c-archive", "-o"])
        .arg(&static_lib)
        .status()
        .expect("failed to execute go build");

    if !status.success() {
        panic!("go build failed");
    }

    println!("cargo:rustc-link-search=native={}", out_dir.display());
    println!("cargo:rustc-link-lib=static={}", lib_name);

    // 链接系统库（根据平台）
    if cfg!(target_os = "macos") {
        println!("cargo:rustc-link-lib=framework=SystemConfiguration");
        println!("cargo:rustc-link-lib=framework=CoreFoundation");
    } else if cfg!(target_os = "linux") {
        println!("cargo:rustc-link-lib=dl");
        println!("cargo:rustc-link-lib=pthread");
    }
    // Windows 下 Go 的 c-archive 通常无需额外链接

    println!("cargo:rerun-if-changed=go");
}