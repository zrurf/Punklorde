import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:punklorde/core/status/device.dart' as device;
import 'package:punklorde/module/platform/chaoxing/constant.dart' as constant;
import 'package:punklorde/utils/ua.dart';

class UAConfig {
  final bool iOS;
  final String uniqueId;

  final String appVersion;
  final String versionCode;
  final String apiVersion;

  const UAConfig({
    required this.iOS,
    required this.uniqueId,
    this.appVersion = constant.appVersion,
    this.versionCode = constant.appVersionCode,
    this.apiVersion = constant.apiVersion,
  });
}

/// 生成超星UA
String genUA(UAConfig config) {
  final header = config.iOS
      ? UAUtil.getUA(.raw, useRealSystem: false, targetOS: 'ios_raw')
      : "Dalvik/2.1.0 (Linux; U; Android ${device.deviceOSVersion}; ${device.deviceModel} Build/${device.deviceProduct})";
  final body =
      "(device:${device.deviceModel}) Language/zh_CN ${(config.iOS) ? 'com.ssreader.ChaoXingStudy' : 'com.chaoxing.mobile'}/ChaoXingStudy_3_${config.appVersion}_${(config.iOS ? 'ios' : 'android')}_phone_${config.versionCode}_${config.apiVersion} (@Kalimdor)_${config.uniqueId}";
  final schild = md5.convert(
    utf8.encode("(schild:${constant.schildSalt}) $body"),
  );
  return "$header (schild:$schild) $body";
}
