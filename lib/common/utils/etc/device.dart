import 'dart:io';

import 'package:punklorde/core/status/device.dart';

enum UAType { raw, wechat, wxwork, wxapplet }

String getUA(UAType type) {
  final String baseUA =
      "Mozilla/5.0 (${(Platform.isAndroid) ? 'Linux; Android $deviceOSVersion; $deviceModel' : 'iPhone; CPU iPhone OS ${deviceOSVersion.replaceAll(".", "_")}'} ${(Platform.isAndroid) ? 'Build/$deviceProduct; wv' : 'like Mac OS X'}) AppleWebKit/${(Platform.isAndroid) ? '537.36' : '605.1.15'} (KHTML, like Gecko) Version/${(Platform.isAndroid) ? '4.0' : deviceOSVersion} ${(Platform.isAndroid) ? 'Chrome/107.0.5304.91 Mobile' : 'Mobile/15E148'} Safari/537.36";
  switch (type) {
    case UAType.raw:
      return baseUA;
    case UAType.wechat:
      return "$baseUA XWEB/1420087 MMWEBSDK/20251006 MMWEBID/7533 MicroMessenger/8.0.66.2980(0x2800423B) WeChat/arm64 Weixin NetType/5G Language/zh_CN ABI/arm64";
    case UAType.wxapplet:
      return "$baseUA XWEB/1420087 MMWEBSDK/20251006 MMWEBID/7533 MicroMessenger/8.0.66.2980(0x2800423B) WeChat/arm64 Weixin NetType/WIFI Language/zh_CN ABI/arm64 miniProgram";
    case UAType.wxwork:
      return "$baseUA XWEB/1380275 MMWEBSDK/20250202 MMWEBID/1324 wxwork/5.0.2 MicroMessenger/7.0.1 NetType/4G Language/zh Lang/zh ColorScheme/Light wwmver/3.26.502.634";
  }
}
