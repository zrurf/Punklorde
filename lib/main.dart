import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mmkv/mmkv.dart';
import 'package:punklorde/app/main.dart';
import 'package:punklorde/common/utils/etc/style.dart';
import 'package:punklorde/common/utils/notification.dart';
import 'package:punklorde/common/utils/permission/checker.dart';
import 'package:punklorde/core/services/lbs/location.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/school.dart';
import 'package:punklorde/core/status/store.dart';
import 'package:punklorde/core/store/local/auth.dart';
import 'package:punklorde/features/schools/schools.dart';

Future main() async {
  // 初始化UI框架
  WidgetsFlutterBinding.ensureInitialized();
  resetSystemChromeStyle();

  // 初始化设备信息
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    deviceOs = "Android";
    var rawInfoAndroid = await deviceInfo.androidInfo;
    deviceOSVersion = rawInfoAndroid.version.sdkInt.toString();
    deviceBrand = rawInfoAndroid.brand;
    deviceModel = rawInfoAndroid.model;
    deviceManufacturer = rawInfoAndroid.manufacturer;
    deviceName = rawInfoAndroid.name;
    deviceProduct = rawInfoAndroid.product;
  }
  if (Platform.isIOS) {
    deviceOs = "iOS";
    var rawInfoIOS = await deviceInfo.iosInfo;
    deviceOSVersion = rawInfoIOS.systemVersion;
    deviceBrand = "iPhone";
    deviceModel = rawInfoIOS.model;
    deviceManufacturer = "Apple";
    deviceName = rawInfoIOS.name;
    deviceProduct = rawInfoIOS.utsname.machine;
  }

  // 初始化环境变量
  await dotenv.load(fileName: ".env");

  if (dotenv.env["MMKV_KEY"] == null) {
    throw "MMKV_KEY is not set in .env file";
  }

  mmkvKey = dotenv.env["MMKV_KEY"]!;

  // 初始化MMKV存储器
  final rootDir = await MMKV.initialize();

  // 初始化百度地图
  BMFMapSDK.setAgreePrivacy(true);
  if (Platform.isAndroid) await BMFAndroidVersion.initAndroidVersion();
  if (Platform.isIOS) {
    if (dotenv.env["BAIDU_MAP_APIKEY_IOS"] == null) {
      throw "BAIDU_MAP_APIKEY_IOS is not set in .env file";
    }
    BMFMapSDK.setApiKeyAndCoordType(
      dotenv.env["BAIDU_MAP_APIKEY_IOS"]!,
      BMF_COORD_TYPE.COMMON,
    );
  }
  BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);

  // 初始化定位服务
  initLocationService();

  // 初始化学校信息
  currentSchool.value = schools["cqupt"];

  authManager.initWithSchool(currentSchool.value!);

  // 初始化身份信息存储器
  initAuthStore();

  // 刷新身份验证数据
  authManager.refreshAll();

  // 检查权限
  checkAndRequestPermissions(.notice);

  // 初始化通知服务
  initNoticationPlugin();

  runApp(const MainApp());
}
