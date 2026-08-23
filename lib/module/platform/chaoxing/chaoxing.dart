import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' hide RSAPublicKey;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypt_next/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:loader_overlay/loader_overlay.dart';
import 'package:pointycastle/export.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/device.dart' as device;
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:punklorde/module/platform/chaoxing/constant.dart';
import 'package:punklorde/module/platform/chaoxing/model.dart';
import 'package:punklorde/module/platform/chaoxing/utils/ua.dart';
import 'package:punklorde/module/platform/chaoxing/view/login.dart';
import 'package:punklorde/module/service/vault/vault_dialog.dart';
import 'package:punklorde/utils/ua.dart';

class ChaoxingPlatform extends Platform {
  static const _domain = "https://chaoxing.com";
  static const _apiLogin = "https://passport2.chaoxing.com/fanyalogin";
  static const _apiAppLogin =
      "https://passport2-api.chaoxing.com/v11/loginregister?cx_xxt_passport=json";
  static const _apiInfo =
      "https://sso.chaoxing.com/apis/login/userLogin4Uname.do?_from=passport&js=true";
  static const _apiSendCode =
      "https://passport2-api.chaoxing.com/api/sendcaptcha";

  @override
  String get id => "chaoxing";

  @override
  String get name => "学习通";

  @override
  String get descript => "用于学习通";

  static const int MAX_ENCRYPT_BLOCK = 117;
  static const int MAX_DECRYPT_BLOCK = 128;
  late final AesCbc _cryptoCbc;
  Encrypter? _rsaCrypto;
  RSAPublicKey? _rsaPublicKey;

  late final Dio _dio;

  ChaoxingPlatform() {
    _cryptoCbc = AesCbc.with128bits(
      macAlgorithm: .empty,
      paddingAlgorithm: .pkcs7,
    );

    initRsaCrypto();

    _dio = Dio(
      BaseOptions(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        validateStatus: (status) => true,
      ),
    );
  }

  Future<void> initRsaCrypto() async {
    final pemString = await rootBundle.loadString(
      'assets/module/chaoxing/certs/device_info.pub.pem',
    );
    _rsaPublicKey = RSAKeyParser().parse(pemString) as RSAPublicKey;
    _rsaCrypto = Encrypter(
      RSA(publicKey: _rsaPublicKey!, encoding: .PKCS1, digest: .SHA256),
    );
  }

  Future<AuthCredential?> _login(
    BuildContext context,
    ChaoxingLoginConfig config,
  ) async {
    final isIos = !(config.deviceConfig?.isAndroid ?? true);
    final deviceId = genDeviceId(isIos ? 'ios' : 'android', config.phone);
    final deviceInfo = _buildDeviceInfo(config.deviceConfig, deviceId);

    switch (config.method) {
      case .pwd:
        return _loginWeb(config, deviceInfo, deviceId);
      case .sms:
        return _loginApp(config, deviceInfo, deviceId);
      case .qrcode:
        return null;
    }
  }

  /// 网页登录
  Future<AuthCredential?> _loginWeb(
    ChaoxingLoginConfig config,
    ChaoxingDeviceInfo deviceInfo,
    String deviceId,
  ) async {
    final CookieJar cookieJar = CookieJar();
    final CookieManager cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);
    final loginKey = utf8.encode(webLoginSalt);
    final isIos = !(config.deviceConfig?.isAndroid ?? true);
    final ua = genUA(UAConfig(iOS: isIos, uniqueId: deviceId));
    final phoneRes = await _cryptoCbc.encrypt(
      utf8.encode(config.phone),
      secretKey: .new(loginKey),
      nonce: loginKey,
    );
    final pwdRes = await _cryptoCbc.encrypt(
      utf8.encode(config.value),
      secretKey: .new(loginKey),
      nonce: loginKey,
    );
    final formData = {
      'fid': '-1',
      'uname': base64.encode(phoneRes.cipherText),
      'password': base64.encode(pwdRes.cipherText),
      't': 'true',
      'forbidotherlogin': '0',
      'validate': '',
      'doubleFactorLogin': '0',
    };
    try {
      final deviceInfoData = await _getDeviceInfo(
        config.deviceConfig,
        deviceId,
      );
      if (deviceInfoData == null) return null;
      final r1 = await _dio.post(
        _apiLogin,
        data: FormData.fromMap(formData),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"User-Agent": ua},
        ),
      );
      final data1 = json.decode(r1.data);
      if (r1.statusCode != 200 || data1 == null || data1["status"] != true) {
        return null;
      }
      final r2 = await _dio.post(
        _apiInfo,
        data: FormData.fromMap({"data": deviceInfoData}),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"User-Agent": ua},
        ),
      );
      final data2 = json.decode(r2.data);
      if (r2.statusCode != 200 || data2 == null || data2["msg"] == null) {
        return null;
      }
      final uid = data2["msg"]["puid"];
      final uname = data2["msg"]["name"];
      final avatar = data2["msg"]["pic"];
      final phone2 = data2["msg"]["phone"];
      final clientId = data2["msg"]["clientId"];
      final clientInfo = await _decryptClientInfo(clientId);
      if (uid == null ||
          uname == null ||
          avatar == null ||
          phone2 == null ||
          clientId == null ||
          clientInfo == null) {
        return null;
      }
      final exp = await _getExpireTime(cookieJar);
      if (exp == null) return null;
      return AuthCredential(
        guest: false,
        type: id,
        id: uid.toString(),
        name: uname,
        token: '',
        expireAt: exp,
        ext: {
          "ua": ua,
          "device_id": deviceId,
          "avatar": avatar,
          "phone": phone2,
          "client_id": clientId,
          "device_info": deviceInfoData,
          "client_info": clientInfo,
          "cookie": await serializeCookieJar(cookieJar, {_domain}),
        },
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// APP登录
  Future<AuthCredential?> _loginApp(
    ChaoxingLoginConfig config,
    ChaoxingDeviceInfo deviceInfo,
    String deviceId,
  ) async {
    final ecb = Encrypter(
      AES(.fromUtf8(appLoginSalt), mode: .ecb, padding: "PKCS7"),
    );

    final CookieJar cookieJar = CookieJar();
    final CookieManager cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);
    final isIos = !(config.deviceConfig?.isAndroid ?? true);
    final ua = genUA(UAConfig(iOS: isIos, uniqueId: deviceId));

    final loginData = {'uname': config.phone, 'code': config.value};
    final loginInfo = ecb.encrypt(json.encode(loginData)).base64;

    final formData = {
      'logininfo': loginInfo,
      'loginType': switch (config.method) {
        .pwd => '1',
        .sms => '2',
        .qrcode => '3',
      },
      'roleSelect': 'true',
      'entype': "1",
    };
    if (config.method == .sms) {
      formData['countrycode'] = '86';
    }
    try {
      final deviceInfoData = await _getDeviceInfo(
        config.deviceConfig,
        deviceId,
      );
      if (deviceInfoData == null) return null;
      final r1 = await _dio.post(
        _apiAppLogin,
        data: FormData.fromMap(formData),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"User-Agent": ua},
        ),
      );
      final data1 = json.decode(r1.data);
      if (r1.statusCode != 200 || data1 == null || data1["status"] != true) {
        return null;
      }
      final r2 = await _dio.post(
        _apiInfo,
        data: FormData.fromMap({"data": deviceInfoData}),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"User-Agent": ua},
        ),
      );
      final data2 = json.decode(r2.data);
      if (r2.statusCode != 200 || data2 == null || data2["msg"] == null) {
        return null;
      }
      final uid = data2["msg"]["puid"];
      final uname = data2["msg"]["name"];
      final avatar = data2["msg"]["pic"];
      final phone2 = data2["msg"]["phone"];
      final clientId = data2["msg"]["clientId"];
      final clientInfo = await _decryptClientInfo(clientId);
      if (uid == null ||
          uname == null ||
          avatar == null ||
          phone2 == null ||
          clientId == null ||
          clientInfo == null) {
        return null;
      }
      final exp = await _getExpireTime(cookieJar);
      if (exp == null) return null;
      return AuthCredential(
        guest: false,
        type: id,
        id: uid.toString(),
        name: uname,
        token: '',
        expireAt: exp,
        ext: {
          "ua": genUA(UAConfig(iOS: isIos, uniqueId: deviceId)),
          "device_id": deviceId,
          "avatar": avatar,
          "phone": phone2,
          "client_id": clientId,
          "device_info": deviceInfoData,
          "client_info": clientInfo,
          "cookie": await serializeCookieJar(cookieJar, {_domain}),
        },
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 获取验证码
  Future<bool> _sendVerifyCode(String phone, String ua) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final formData = FormData.fromMap({
      'to': phone,
      'countrycode': '86',
      'time': ts,
      'enc': md5.convert(utf8.encode("$phone$smsCaptchaSalt$ts")).toString(),
    });
    try {
      final r = await _dio.post(
        _apiSendCode,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"User-Agent": ua},
        ),
      );
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthCredential?> login(BuildContext context, bool isGuest) async {
    final completer = Completer<ChaoxingLoginConfig?>();

    await Navigator.of(context).push<ChaoxingLoginConfig>(
      MaterialPageRoute(
        builder: (_) => ChaoxingLoginPage(
          sendVerifyCode:
              (String phone, ChaoxingDeviceConfig? deviceConfig) async {
                final isIos = !(deviceConfig?.isAndroid ?? true);
                final deviceId = genDeviceId(isIos ? 'ios' : 'android', phone);
                await _sendVerifyCode(
                  phone,
                  genUA(UAConfig(iOS: isIos, uniqueId: deviceId)),
                );
              },
          onConfirm: (values) {
            if (!completer.isCompleted) {
              completer.complete(values);
            }
          },
        ),
        fullscreenDialog: true,
      ),
    );

    final result = await completer.future;

    if (result == null || !context.mounted) return null;
    context.loaderOverlay.show();
    AuthCredential? credential;
    try {
      credential = await _login(context, result);
    } finally {
      if (context.mounted) context.loaderOverlay.hide();
    }
    if (credential != null &&
        !isGuest &&
        result.method == .pwd &&
        context.mounted) {
      showVaultSavePrompt(
        context,
        schoolId: currentSchoolSignal.value?.id ?? '',
        platformId: id,
        accountType: loginAccountType,
        username: result.phone,
        password: result.value,
      );
    }
    return credential?.copyWith(guest: isGuest);
  }

  @override
  Future<void> logout(AuthCredential credential) async {
    return;
  }

  @override
  Future<AuthCredential?> refresh(AuthCredential oldCredential) async {
    final rawMap = oldCredential.ext!['cookie'] as Map<Object?, Object?>;
    final cookieMap = rawMap.map((key, value) {
      return MapEntry(key.toString(), List<String>.from(value as List));
    });
    final cookie = await deserializeCookieJar(cookieMap);
    final CookieManager cookieManager = CookieManager(cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final r1 = await _dio.post(
        _apiInfo,
        data: FormData.fromMap({"data": oldCredential.ext?["device_info"]}),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "User-Agent": oldCredential.ext?["ua"] ?? UAUtil.getUA(.raw),
          },
        ),
      );
      final data1 = json.decode(r1.data);
      if (r1.statusCode != 200 || data1 == null || data1["msg"] == null) {
        return null;
      }
      final ext = oldCredential.ext ?? {};
      final clientId = data1["msg"]["clientId"];
      if (clientId != null) {
        ext["client_id"] = clientId;
        ext["client_info"] = await _decryptClientInfo(clientId);
      }
      ext["cookie"] = await serializeCookieJar(cookie, {_domain});
      final exp = await _getExpireTime(cookie);
      if (exp == null) return null;
      return oldCredential.copyWith(expireAt: exp, ext: ext);
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  @override
  Future<bool> validate(AuthCredential credential) async {
    final rawMap = credential.ext!['cookie'] as Map<Object?, Object?>;
    final cookieMap = rawMap.map((key, value) {
      return MapEntry(key.toString(), List<String>.from(value as List));
    });
    final cookie = await deserializeCookieJar(cookieMap);
    final CookieManager cookieManager = CookieManager(cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final r = await _dio.post(
        _apiInfo,
        options: Options(
          headers: {"User-Agent": credential.ext?["ua"] ?? UAUtil.getUA(.raw)},
        ),
      );
      final data = json.decode(r.data);
      return (data["result"] == 1 && data["msg"] != null);
    } catch (e) {
      return false;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 获取 Cookie 的有效期
  Future<DateTime?> _getExpireTime(CookieJar cookie) async {
    final cookies = await cookie.loadForRequest(Uri.parse(_domain));
    final authCookie = cookies
        .where((v) => v.name == "p_auth_token")
        .firstOrNull;
    if (authCookie == null) {
      return null;
    }
    final jwt = JWT.tryDecode(authCookie.value);
    if (jwt == null) return null;
    final exp = jwt.payload["exp"];
    if (exp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  ChaoxingDeviceInfo _buildDeviceInfo(
    ChaoxingDeviceConfig? config,
    String deviceId,
  ) {
    final isAndroid = config?.isAndroid ?? true;
    final platform = isAndroid ? 'android' : 'ios';

    final oaid = md5
        .convert(utf8.encode('pkld:${deviceId}_chaoxing_oaid'))
        .toString();

    if (isAndroid) {
      return ChaoxingDeviceInfo(
        platform: platform,
        appName: 'com.chaoxing.mobile',
        cdtype: config?.model ?? device.deviceModel,
        osName: 'REL',
        osVer: config?.osVer ?? device.deviceOSVersion,
        osLang: 'zh_CN',
        cpuAr: 'arm64-v8a',
        resolution: config?.resolution ?? '1080*2400',
        dpi: '480',
        brand: config?.brand ?? device.deviceBrand,
        board: config?.board ?? device.deviceBoard,
        hardware: device.deviceManufacturer,
        deviceId: deviceId,
        oaid: oaid,
      );
    } else {
      return ChaoxingDeviceInfo(
        platform: platform,
        appName: 'com.ssreader.ChaoXingStudy',
        cdtype: config?.model ?? 'iPhone15,2',
        osName: '',
        osVer: config?.osVer ?? '18.0',
        osLang: 'zh_CN',
        cpuAr: 'arm64e',
        resolution: config?.resolution ?? '1170*2532',
        dpi: '460',
        brand: 'iPhone',
        board: 'iPhone',
        hardware: 'iPhone',
        deviceId: deviceId,
        oaid: oaid,
      );
    }
  }

  Future<String?> _getDeviceInfo(
    ChaoxingDeviceConfig? config,
    String deviceId,
  ) async {
    if (_rsaCrypto == null || _rsaPublicKey == null) {
      return null;
    }
    try {
      final deviceInfo = _buildDeviceInfo(config, deviceId);

      final jsonMap = deviceInfo.toJson();

      final mediaDrmId = ChaoxingDeviceInfo.mediaDrmId;
      final cdid = mediaDrmId.isNotEmpty
          ? mediaDrmId
          : (deviceInfo.oaid.isNotEmpty
                ? deviceInfo.oaid
                : deviceInfo.deviceId);
      jsonMap['cdid'] = cdid;

      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      jsonMap['time_stamp'] = timestamp;

      final jsonStr = json.encode(jsonMap);

      return _rsaEncryptBlock(jsonStr);
    } catch (e) {
      return null;
    }
  }

  String _rsaEncryptBlock(String plaintext) {
    final keySize = _rsaPublicKey!.modulus!.bitLength ~/ 8;
    final maxBlockSize = keySize - 11;

    final plainBytes = utf8.encode(plaintext);
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(_rsaPublicKey!));

    final encryptedBytes = <int>[];
    for (var i = 0; i < plainBytes.length; i += maxBlockSize) {
      final end = math.min(i + maxBlockSize, plainBytes.length);
      final block = plainBytes.sublist(i, end);
      encryptedBytes.addAll(cipher.process(block));
    }

    return base64.encode(encryptedBytes);
  }

  Future<String?> _decryptClientInfo(String clientId) async {
    if (_rsaPublicKey == null) {
      return null;
    }
    try {
      AsymmetricBlockCipher cipher = PKCS1Encoding(RSAEngine());
      cipher.init(false, PublicKeyParameter<RSAPublicKey>(_rsaPublicKey!));

      List<int> sourceBytes = base64Decode(clientId);
      //数据长度
      int inputLength = sourceBytes.length;
      // 缓存数组
      List<int> cache = [];
      // 分段解密 步长为MAX_DECRYPT_BLOCK
      for (var i = 0; i < inputLength; i += MAX_DECRYPT_BLOCK) {
        //剩余长度
        int endLen = inputLength - i;
        List<int> item;
        if (endLen > MAX_DECRYPT_BLOCK) {
          item = sourceBytes.sublist(i, i + MAX_DECRYPT_BLOCK);
        } else {
          item = sourceBytes.sublist(i, i + endLen);
        }
        //解密后放到数组缓存
        cache.addAll(cipher.process(Uint8List.fromList(item)));
      }
      return utf8.decode(cache);
    } catch (e) {
      return null;
    }
  }
}

final platChaoxing = ChaoxingPlatform();
