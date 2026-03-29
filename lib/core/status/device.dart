import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:signals/signals.dart';

late final String deviceOs;
late final String deviceOSVersion;
late final String deviceSdkVersion; // Android独有
late final String deviceManufacturer;
late final String deviceBrand;
late final String deviceModel;
late final String deviceName;
late final String deviceProduct;

final rawHeadingRunning = signal<bool>(false);
final rawHeading = signal<double>(0); // 原始设备朝向

final virtualHeadingRunning = signal<bool>(false);
final virtualHeading = signal<double>(0); // 虚拟设备朝向

final Computed<bool> exportHeadingRunning = computed(() {
  return rawHeadingRunning.value || virtualHeadingRunning.value;
}); // 输出设备朝向运行状态

final Computed<double> exportHeading = computed(() {
  return virtualHeadingRunning.value ? virtualHeading.value : rawHeading.value;
}); // 输出设备朝向

Future<void> initDeviceStatus() async {
  // 统一获取设备名称（主机名）
  deviceName = Platform.localHostname;

  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    deviceOs = "Android";
    final androidInfo = await deviceInfo.androidInfo;
    deviceOSVersion = androidInfo.version.release;
    deviceSdkVersion = androidInfo.version.sdkInt.toString();
    deviceBrand = androidInfo.brand;
    deviceModel = androidInfo.model;
    deviceManufacturer = androidInfo.manufacturer;
    deviceProduct = androidInfo.product;
  } else if (Platform.isIOS) {
    deviceOs = "iOS";
    final iosInfo = await deviceInfo.iosInfo;
    deviceOSVersion = iosInfo.systemVersion;
    deviceBrand = "iPhone";
    deviceModel = iosInfo.model;
    deviceManufacturer = "Apple";
    deviceProduct = iosInfo.utsname.machine;
  } else if (Platform.isWindows) {
    deviceOs = "Windows";
    final windowsInfo = await deviceInfo.windowsInfo;
    // 构建 Windows 版本号：major.minor.build
    deviceOSVersion =
        "${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}";
    deviceBrand = windowsInfo.productName; // 如 "Windows 10 Pro"
    deviceManufacturer = ''; // WindowsInfo 无制造商信息
    deviceModel = ''; // WindowsInfo 无硬件型号
    deviceProduct = ''; // WindowsInfo 无产品名
  } else if (Platform.isMacOS) {
    deviceOs = "macOS";
    final macosInfo = await deviceInfo.macOsInfo;
    deviceOSVersion = macosInfo.osRelease; // 例如 "12.6"
    deviceBrand = "Apple";
    deviceManufacturer = "Apple";
    deviceModel = macosInfo.model; // 例如 "MacBookPro18,3"
    deviceProduct = '';
  } else if (Platform.isLinux) {
    deviceOs = "Linux";
    final linuxInfo = await deviceInfo.linuxInfo;
    // 优先使用 versionId（如 "22.04"），否则使用完整 version
    deviceOSVersion = linuxInfo.versionId ?? linuxInfo.version ?? '';
    deviceBrand = linuxInfo.name; // 发行版名称，如 "Ubuntu"
    deviceManufacturer = ''; // LinuxInfo 无制造商
    deviceModel = ''; // LinuxInfo 无硬件型号
    deviceProduct = ''; // LinuxInfo 无产品名
  } else {
    // 未知平台（如 Fuchsia）
    deviceOs = "Unknown";
    deviceOSVersion = '';
    deviceBrand = '';
    deviceManufacturer = '';
    deviceModel = '';
    deviceProduct = '';
  }
}
