import 'dart:io';

import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';

Future<void> initMapService(String iosKey) async {
  BMFMapSDK.setAgreePrivacy(true);
  if (Platform.isAndroid) await BMFAndroidVersion.initAndroidVersion();
  if (Platform.isIOS) {
    BMFMapSDK.setApiKeyAndCoordType(iosKey, BMF_COORD_TYPE.COMMON);
  }
  BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);
}
