# 编译和运行

## 1. 环境准备

构建本应用需要以下工具链：

| 组件               | 最低版本                 | 说明                                                                 |
|--------------------|--------------------------|----------------------------------------------------------------------|
| **Flutter**        | 3.41.0                   | 需包含 Dart SDK。建议使用稳定版（stable）。                          |
| **Rust**           | 1.85 (Edition 2024)      | 用于部分原生模块。需安装 `cargo` 并将 `rustc` 加入 PATH。            |
| **Go**             | 1.25.0                   | 用于某些后端工具链。确保 `go` 命令可用。                              |
| **C/C++ 编译器**    | 支持 CGO 调用即可         | Linux 安装 `gcc` / `g++`，macOS 安装 Xcode Command Line Tools，Windows 安装 MSVC 或 MinGW。 |
| **CMake**          | 任意稳定版                | 用于原生构建系统。                                                    |

> **注意**：若构建Android应用，需要按照Android Studio以及Android SDK和NDK；若在 macOS 上构建 iOS 应用，请确保已安装 Xcode 及 Xcode Command Line Tools。

## 2. 平台特定要求

### 2.1 Android

构建 Android 应用需要额外安装以下组件：

- **Android SDK**：版本 36 或更高。
- **Android NDK**：版本 r28 或更高。
- **JDK**：Java 25 推荐，最低 Java 21。
- **编译配置**：
  - `compileSdkVersion` ≥ 36
  - `minSdkVersion` ≥ 26（对应 Android 8.0）

### 2.2 iOS

当前 iOS 平台**缺乏维护与测试**，可能无法稳定运行。如需尝试构建，请确保：

- macOS 系统，Xcode 安装完整。
- 具备 Apple 开发者账号（用于签名）。
- 了解 iOS 构建的基本流程。

需请自行补充测试与维护。

## 3. 签名配置

### 3.1 Android 签名

应用需要数字证书进行签名，您需自行生成密钥库（keystore）并配置签名信息。

1. **生成密钥库**（如尚未拥有）：
   ```bash
   keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
   ```
   按提示填写信息，并记住密钥库密码、别名及别名密码。

2. **创建 `key.properties` 文件**：
   在 `android/` 目录下创建 `key.properties` 文件，参考项目中的 `key.properties.template`。内容格式如下：
   ```
   storePassword=你的密钥库密码
   keyPassword=你的别名密码
   keyAlias=my-key-alias
   storeFile=../my-release-key.jks   # 密钥库文件的相对路径（相对于 android/）
   ```

> **重要**：该文件包含敏感信息，请勿提交至版本控制系统。确保密钥库文件本身也妥善保管。

### 3.2 iOS 签名

iOS 应用需使用个人开发者证书或团队证书签名。请通过 Xcode 管理签名，或手动配置描述文件。具体步骤略（因 iOS 构建未完全支持）。

## 4. 构建前配置

应用需要多个 API Key 和服务密钥，这些必须通过配置文件提供。

### 4.1 环境变量文件 `.env`

在项目根目录下创建 `.env` 文件，参考 `.env.template`。该文件包含运行应用所需的各种密钥（例如地图 API Key、推送服务密钥等）。

**必填项**（根据模板实际字段填写）：
```ini
# MMKV KEY
MMKV_KEY=

# 百度地图API KEY (Android)
BAIDU_MAP_APIKEY_ANDROID=

# 百度地图API KEY (iOS)
BAIDU_MAP_APIKEY_IOS=
```

> **注意**：`.env` 用于 Dart 代码生成，请勿留空或使用占位符，否则生成失败。

### 4.2 Android 本地属性文件 `local.properties`

在 `android/` 目录下创建 `local.properties`，参考 `local.properties.template`。通常用于指定 Android SDK 路径和 NDK 路径，例如：
```properties
sdk.dir=C:/Users/你的用户名/Library/Android/sdk
flutter.sdk=D:/Flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
baidu_map_key=你的BAIDU_MAP_KEY #必填，Android不允许使用env文件使用API_KEY
```

> **注意**：上述路径需要替换为你的真实路径。。

### 4.3 申请 API Key

上述配置中涉及的各类 API Key 均需您自行向相应服务商申请。目前包括：
- 百度地图 API Key

请参照项目需求申请并填入对应位置。

## 5. 构建流程

完成配置后，按以下步骤生成源码并构建应用。

### 5.1 生成 Dart 代码

项目使用了 `build_runner` 和 `slang` 进行代码生成，执行以下命令：

```bash
# 获取依赖
flutter pub get

# 生成代码
dart run build_runner build

# 生成国际化文件
dart run slang
```

执行后，检查 `lib/env.g.dart` 是否已生成，且无报错。若出错，请检查配置文件（`.env`、`key.properties` 等）是否完整且格式正确。

### 5.2 构建应用

#### 5.2.1 构建 Android APK / App Bundle

```bash
# 构建 release APK
flutter build apk --release

# 或构建 App Bundle（推荐上传 Google Play）
flutter build appbundle --release
```

构建产物位于 `build/app/outputs/` 相应目录下。

#### 5.2.2 构建 iOS（试验性）

```bash
flutter build ios --release
```

若遇到签名问题，请在 Xcode 中打开 `ios/Runner.xcworkspace`，配置好签名后再执行构建。

## 6. 常见问题
以下是编译时常见的问题，部分问题需要您手动解决。

### rust_builder/cargokit/build_tool依赖错误
手动执行以下命令：
```bash 
flutter pub get -C ./rust_builder
flutter pub get -C ./rust_builder/cargokit/build_tool
```

### Android编译：Could not resolve io.flutter:flutter_embedding_debug
**报错信息：**
```
    > Could not resolve io.flutter:arm64_v8a_debug:1.0.0-e4b8dca3f1b4ede4c30371002441c88c12187ed6.
    > Could not get resource 'https://maven.aliyun.com/repository/content/groups/public/io/flutter/arm64_v8a_debug/1.0.0-e4b8dca3f1b4ede4c30371002441c88c12187ed6/arm64_v8a_debug-1.0.0-e4b8dca3f1b4ede4c30371002441c88c12187ed6.pom'.
    > Could not GET 'https://maven.aliyun.com/repository/content/groups/public/io/flutter/arm64_v8a_debug/1.0.0-e4b8dca3f1b4ede4c30371002441c88c12187ed6/arm64_v8a_debug-1.0.0-e4b8dca3f1b4ede4c30371002441c88c12187ed6.pom'. Received status code 401 from server: Unauthorized
    Required by:
        project ':app'
        ...
```
**原因：**

由于百度地图往代码中塞了错误的maven仓库地址（`https://maven.aliyun.com/repository/content/groups/public/`），导致无法正常下载依赖。

**解决方法：**

手动修改百度地图相关插件的下载缓存，删除所有gradle脚本里`https://maven.aliyun.com/repository/content/groups/public/`这个maven仓库。推荐使用**Everything**来查找和修改。
