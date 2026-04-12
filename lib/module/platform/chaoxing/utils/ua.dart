import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt_next/encrypt.dart';
import 'package:punklorde/core/status/device.dart' as device;
import 'package:punklorde/module/platform/chaoxing/constant.dart' as constant;
import 'package:punklorde/utils/ua.dart';
import 'package:punklorde/utils/uuid.dart';

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
  final header = UAUtil.getUA(
    .raw,
    useRealSystem:
        (config.iOS && device.deviceOs.toLowerCase() == 'ios') ||
        (!config.iOS && device.deviceOs.toLowerCase() == 'android'),
    targetOS: (config.iOS) ? 'ios_raw' : 'android',
  );
  final body =
      "(device:${device.deviceModel}) Language/zh_CN ${(config.iOS) ? 'com.ssreader.ChaoXingStudy' : 'com.chaoxing.mobile'}/ChaoXingStudy_3_${config.appVersion}_${(config.iOS ? 'ios' : 'android')}_phone_${config.versionCode}_${config.apiVersion} (@Kalimdor)_${config.uniqueId}";
  final schild = md5.convert(
    utf8.encode("(schild:${constant.schildSalt}) $body"),
  );
  return "$header (schild:${schild.toString()}) $body";
}

/// 生成确定性设备 ID
String genDeviceId(String os, String phoneNum) =>
    DeterministicUuidUtil.generate("pkld:${os}_$phoneNum");

/// 生成确定性设备指纹
String genDeviceFingerprint(String deviceId) {
  final ecb = Encrypter(
    AES(.fromUtf8(constant.deviceCodeSalt), mode: .ecb, padding: "PKCS7"),
  );
  return ecb.encrypt(json.encode(deviceId)).base64;
}
