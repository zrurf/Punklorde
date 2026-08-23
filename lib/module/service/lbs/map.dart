import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:punklorde/env.dart';

/// 地图实现
enum MapProviderType {
  baidu, // 百度地图
  tencent, // 腾讯地图（暂未集成）
}

extension MapProviderTypeX on MapProviderType {
  /// 编译时是否提供了对应平台的 API Key
  bool get available => switch (this) {
    MapProviderType.baidu => _baiduKeyAvailable,
    MapProviderType.tencent => false,
  };

  String get raw => switch (this) {
    MapProviderType.baidu => 'baidu',
    MapProviderType.tencent => 'tencent',
  };

  String get displayName => switch (this) {
    MapProviderType.baidu => '百度地图',
    MapProviderType.tencent => '腾讯地图',
  };

  static MapProviderType? fromRaw(String? raw) {
    return switch (raw) {
      'baidu' => MapProviderType.baidu,
      'tencent' => MapProviderType.tencent,
      _ => null,
    };
  }
}

bool get _baiduKeyAvailable {
  final isAndroid = !kIsWeb && Platform.isAndroid;
  return isAndroid
      ? Env.keyBaiduMapAndroid.isNotEmpty
      : Env.keyBaiduMapIOS.isNotEmpty;
}

/// 当前可用的地图实现列表
List<MapProviderType> get availableMapProviders {
  return MapProviderType.values.where((e) => e.available).toList();
}

/// 初始化地图服务（按编译时提供的 Key 初始化对应实现）
Future<void> initMapService() async {
  if (!_baiduKeyAvailable) return;

  BMFMapSDK.setAgreePrivacy(true);
  if (!kIsWeb && Platform.isAndroid) {
    await BMFAndroidVersion.initAndroidVersion();
  }
  if (!kIsWeb && Platform.isIOS) {
    BMFMapSDK.setApiKeyAndCoordType(
      Env.keyBaiduMapIOS,
      BMF_COORD_TYPE.COMMON,
    );
  }
  BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);
}