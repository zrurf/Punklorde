import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:punklorde/app/main.dart';
import 'package:punklorde/core/resource/model.dart';
import 'package:punklorde/core/service/widget_service.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/resource.dart';
import 'package:punklorde/core/status/schedule.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/env.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/index.dart';
import 'package:punklorde/module/service/lbs/location.dart';
import 'package:punklorde/module/service/lbs/map.dart';
import 'package:punklorde/src/rust/frb_generated.dart';
import 'package:punklorde/utils/etc/style.dart';
import 'package:punklorde/utils/permission.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  // 初始化Rust lib
  await RustLib.init();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  resetSystemChromeStyle();

  // 初始化设备状态
  await initDeviceStatus();

  // 初始化存储服务
  await StorageService().init();
  await initMMKV(Env.keyMmkv);
  await initStatus();

  // 初始化i18n
  await LocaleSettings.useDeviceLocale();

  // 初始化资源管理器
  await setupResourceManager(
    dio: Dio(),
    sources: [
      Source(
        id: "default",
        baseUrl: "https://cdn.jsdelivr.net/gh/zrurf/PunklordeAssets@main/",
      ),
    ],
  );

  // 初始化服务
  await initMapService(Env.keyBaiduMapIOS);
  initLocationService();

  // 获取权限
  checkAndRequestPermission(.notice);

  // 加载状态
  await loadStatus().then((v) {
    // 同步状态
    syncStatus();
  });

  FlutterNativeSplash.remove();
  runApp(TranslationProvider(child: MainMobileApp()));
}

// 初始化状态
Future<void> initStatus() async {
  try {
    loadAppStatus();
    await loadAuthStatus();
  } catch (e) {
    print(e);
  }

  initAppStatus();
  initAuthStatus();
}

// 加载状态
Future<void> loadStatus() async {
  try {
    await loadSemester();
    await loadScheduleStatus();
  } catch (e) {
    print(e);
  }
  initScheduleStatus();

  initChaoxingServices();
}

// 同步状态
Future<void> syncStatus() async {
  // 刷新所有已过时的凭据
  await authManager.refreshAllOutDated();
  if (lastScheduleUpdateTimeSignal.value == null ||
      DateTime.now().difference(
            lastScheduleUpdateTimeSignal.value ?? DateTime.now(),
          ) >=
          const Duration(days: 1)) {
    await pullSchedule();
  }
  // 更新小组件
  await ScheduleWidgetService.updateWidget();
}
