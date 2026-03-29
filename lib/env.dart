import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'MMKV_KEY')
  static final String keyMmkv = _Env.keyMmkv;

  @EnviedField(varName: 'BAIDU_MAP_APIKEY_ANDROID')
  static final String keyBaiduMapAndroid = _Env.keyBaiduMapAndroid;

  @EnviedField(varName: 'BAIDU_MAP_APIKEY_IOS')
  static final String keyBaiduMapIOS = _Env.keyBaiduMapIOS;
}
