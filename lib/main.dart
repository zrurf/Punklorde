import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:punklorde/app/main.dart';
import 'package:mmkv/mmkv.dart';
import 'package:punklorde/common/utils/etc/style.dart';
import 'package:punklorde/core/services/lbs/location.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  resetSystemChromeStyle();

  BMFMapSDK.setAgreePrivacy(true);

  await BMFAndroidVersion.initAndroidVersion();
  BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);

  initLocationService();

  runApp(const MainApp());
}
