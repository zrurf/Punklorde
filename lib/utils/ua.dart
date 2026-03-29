import 'dart:io' show Platform;
import 'package:punklorde/core/status/device.dart' as device;

/// UA类型枚举
enum UAType {
  raw, // 无任何附加标识
  wechat, // 微信内置浏览器
  wxapplet, // 微信小程序
  wxwork, // 企业微信
}

/// UA生成工具类
class UAUtil {
  /// 生成User-Agent字符串
  /// [type] UA类型（raw/wechat/wxapplet/wxwork）
  /// [useRealSystem] 是否使用当前设备的真实信息（否则使用[targetOS]伪装）
  /// [targetOS] 目标操作系统（仅在[useRealSystem]=false时生效），可选值：android/ios/windows/macos/linux
  static String getUA(
    UAType type, {
    bool useRealSystem = true,
    String? targetOS,
  }) {
    // 1. 生成基础UA
    String baseUA;
    if (useRealSystem) {
      // 获取真实系统信息
      final os = Platform.operatingSystem.toLowerCase();
      final version = _getRealOSVersion();
      final model = _getRealModel();
      final product = _getRealProduct();
      baseUA = _buildBaseUA(
        os: os,
        version: version,
        model: model,
        product: product,
      );
    } else {
      // 伪装到指定系统
      if (targetOS == null) {
        throw ArgumentError(
          'targetOS must be provided when useRealSystem is false',
        );
      }
      final os = targetOS.toLowerCase();
      final version = _getMockVersionForOS(os);
      final model = _getMockModelForOS(os);
      final product = _getMockProductForOS(os);
      baseUA = _buildBaseUA(
        os: os,
        version: version,
        model: model,
        product: product,
      );
    }

    // 2. 根据类型添加后缀
    return baseUA + _getSuffixForType(type);
  }

  /// 构建基础UA（根据操作系统类型、版本、型号、产品）
  static String _buildBaseUA({
    required String os,
    required String version,
    String? model,
    String? product,
  }) {
    os = os.toLowerCase();
    // 提取纯净数字版本（例如从 "10.0.22621" 提取 "10.0.22621"）
    final rawVersion = _extractVersion(version);

    if (os == 'android') {
      final androidVersion = rawVersion; // 直接使用，如 "13"
      final deviceModel = model?.isNotEmpty == true ? model : 'unknown';
      final buildId = product?.isNotEmpty == true ? ' Build/$product;' : '';
      return "Mozilla/5.0 (Linux; Android $androidVersion; $deviceModel$buildId wv) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.7204.180 Mobile Safari/537.36";
    } else if (os == 'ios_raw') {
      final iosVersion = rawVersion; // 例如 "17.0"
      final iosVersionForCPU = iosVersion.replaceAll('.', '_');
      return "Mozilla/5.0 (iPhone; CPU iPhone OS $iosVersionForCPU like Mac OS X) "
          "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/$iosVersion Mobile/15E148";
    } else if (os == 'ios') {
      final iosVersion = rawVersion; // 例如 "17.0"
      final iosVersionForCPU = iosVersion.replaceAll('.', '_');
      return "Mozilla/5.0 (iPhone; CPU iPhone OS $iosVersionForCPU like Mac OS X) "
          "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/$iosVersion Mobile/15E148 Safari/604.1";
    } else if (os == 'windows') {
      // Windows NT 版本通常只取主次版本，如 "10.0"
      final parts = rawVersion.split('.');
      final winVersion = (parts.length >= 2)
          ? '${parts[0]}.${parts[1]}'
          : rawVersion;
      return "Mozilla/5.0 (Windows NT $winVersion; Win64; x64) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.7204.180 Safari/537.36";
    } else if (os == 'macos') {
      final macVersion = rawVersion.replaceAll('.', '_');
      return "Mozilla/5.0 (Macintosh; Intel Mac OS X $macVersion) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.7204.180 Safari/537.36";
    } else if (os == 'linux') {
      return "Mozilla/5.0 (X11; Linux x86_64) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.7204.180 Safari/537.36";
    } else {
      throw UnsupportedError('Unsupported OS: $os');
    }
  }

  /// 获取真实操作系统版本（优先使用device.dart中的变量，否则回退到Platform）
  static String _getRealOSVersion() {
    // 如果deviceOSVersion存在且非空，直接使用
    if (device.deviceOSVersion.isNotEmpty) {
      return device.deviceOSVersion;
    }
    // 否则使用Platform提供的版本字符串
    return Platform.operatingSystemVersion;
  }

  /// 获取真实设备型号（仅Android等平台有效，桌面平台返回null）
  static String? _getRealModel() {
    if (device.deviceModel.isNotEmpty) {
      return device.deviceModel;
    }
    return null;
  }

  /// 获取真实产品名（仅Android等平台有效，桌面平台返回null）
  static String? _getRealProduct() {
    if (device.deviceProduct.isNotEmpty) {
      return device.deviceProduct;
    }
    return null;
  }

  /// 提取版本字符串中的数字部分（如 "10.0.22621" -> "10.0.22621"）
  static String _extractVersion(String raw) {
    final regex = RegExp(r'(\d+(\.\d+)*)');
    final match = regex.firstMatch(raw);
    return match?.group(0) ?? raw;
  }

  /// 获取伪装目标系统的默认版本号
  static String _getMockVersionForOS(String os) {
    switch (os.toLowerCase()) {
      case 'android':
        return '13';
      case 'ios':
        return '17.0';
      case 'windows':
        return '10.0';
      case 'macos':
        return '10.15.7';
      case 'linux':
        return 'x86_64'; // Linux 通常不报告数字版本
      default:
        return 'unknown';
    }
  }

  /// 获取伪装目标系统的默认型号（仅Android需要）
  static String? _getMockModelForOS(String os) {
    switch (os.toLowerCase()) {
      case 'android':
        return 'SM-G998B'; // 三星S21 Ultra 示例
      case 'ios':
        return null; // iOS UA 一般不包含具体型号
      default:
        return null;
    }
  }

  /// 获取伪装目标系统的默认产品名（仅Android需要）
  static String? _getMockProductForOS(String os) {
    switch (os.toLowerCase()) {
      case 'android':
        return 'AP3A.240905.014'; // 示例构建ID
      default:
        return null;
    }
  }

  /// 根据UA类型获取后缀字符串
  static String _getSuffixForType(UAType type) {
    switch (type) {
      case .raw:
        return '';
      case .wechat:
        return " XWEB/1420087 MMWEBSDK/20251006 MMWEBID/7533 "
            "MicroMessenger/8.0.66.2980(0x2800423B) WeChat/arm64 Weixin NetType/5G Language/zh_CN ABI/arm64";
      case .wxapplet:
        return " XWEB/1420087 MMWEBSDK/20251006 MMWEBID/7533 "
            "MicroMessenger/8.0.66.2980(0x2800423B) WeChat/arm64 Weixin NetType/5G Language/zh_CN ABI/arm64 miniProgram";
      case .wxwork:
        return " XWEB/1380275 MMWEBSDK/20250202 MMWEBID/1324 "
            "wxwork/5.0.2 MicroMessenger/7.0.1 NetType/4G Language/zh Lang/zh ColorScheme/Light wwmver/3.26.500.650";
    }
  }
}
