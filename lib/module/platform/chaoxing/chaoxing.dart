import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypt_next/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:punklorde/module/platform/chaoxing/constant.dart';
import 'package:punklorde/module/platform/chaoxing/model.dart';
import 'package:punklorde/module/platform/chaoxing/utils/ua.dart';
import 'package:punklorde/module/platform/chaoxing/view/login.dart';
import 'package:punklorde/utils/ua.dart';

class ChaoxingPlatform extends Platform {
  static const _domain = "https://chaoxing.com";
  static const _apiLogin = "https://passport2.chaoxing.com/fanyalogin";
  static const _apiAppLogin =
      "https://passport2-api.chaoxing.com/v11/loginregister?cx_xxt_passport=json";
  static const _apiInfo =
      "https://sso.chaoxing.com/apis/login/userLogin4Uname.do";
  static const _apiSendCode =
      "https://passport2-api.chaoxing.com/api/sendcaptcha";

  @override
  String get id => "chaoxing";

  @override
  String get name => "学习通";

  @override
  String get descript => "用于学习通";

  late final AesCbc _cryptoCbc;

  late final Dio _dio;

  ChaoxingPlatform() {
    _cryptoCbc = AesCbc.with128bits(
      macAlgorithm: .empty,
      paddingAlgorithm: .pkcs7,
    );
    _dio = Dio(
      BaseOptions(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        validateStatus: (status) => true,
      ),
    );
  }

  Future<AuthCredential?> _login(
    BuildContext context,
    ChaoxingLoginConfig config,
  ) async {
    switch (config.method) {
      case .pwd:
        return _loginWeb(config);
      case .sms:
        return _loginApp(config);
      case .qrcode:
        return null;
    }
  }

  /// 网页登录
  Future<AuthCredential?> _loginWeb(ChaoxingLoginConfig config) async {
    final CookieJar cookieJar = CookieJar();
    final CookieManager cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);
    final loginKey = utf8.encode(webLoginSalt);
    final deviceId = genDeviceId(
      config.useIosUa ? 'ios' : 'android',
      config.phone,
    );
    final ua = UAUtil.getUA(.raw);
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
      final r2 = await _dio.get(
        _apiInfo,
        options: Options(headers: {"User-Agent": ua}),
      );
      final data2 = json.decode(r2.data);
      if (r2.statusCode != 200 || data2 == null || data2["msg"] == null) {
        return null;
      }
      final uid = data2["msg"]["puid"];
      final uname = data2["msg"]["name"];
      final avatar = data2["msg"]["pic"];
      final phone2 = data2["msg"]["phone"];
      if (uid == null || uname == null || avatar == null || phone2 == null) {
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
          "ua": genUA(UAConfig(iOS: config.useIosUa, uniqueId: deviceId)),
          "device_id": deviceId,
          "avatar": avatar,
          "phone": phone2,
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
  Future<AuthCredential?> _loginApp(ChaoxingLoginConfig config) async {
    final ecb = Encrypter(
      AES(.fromUtf8(appLoginSalt), mode: .ecb, padding: "PKCS7"),
    );

    final CookieJar cookieJar = CookieJar();
    final CookieManager cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);
    final deviceId = genDeviceId(
      config.useIosUa ? 'ios' : 'android',
      config.phone,
    );
    final ua = genUA(UAConfig(iOS: config.useIosUa, uniqueId: deviceId));

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
      final r2 = await _dio.get(
        _apiInfo,
        options: Options(headers: {"User-Agent": ua}),
      );
      final data2 = json.decode(r2.data);
      if (r2.statusCode != 200 || data2 == null || data2["msg"] == null) {
        return null;
      }
      final uid = data2["msg"]["puid"];
      final uname = data2["msg"]["name"];
      final avatar = data2["msg"]["pic"];
      final phone2 = data2["msg"]["phone"];
      if (uid == null || uname == null || avatar == null || phone2 == null) {
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
          "ua": genUA(UAConfig(iOS: config.useIosUa, uniqueId: deviceId)),
          "device_id": deviceId,
          "avatar": avatar,
          "phone": phone2,
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
          sendVerifyCode: (String phone, bool isIos) async {
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

    if (result != null) {
      if (context.mounted) {
        context.loaderOverlay.show();
        return await _login(context, result).then((v) {
          if (context.mounted) context.loaderOverlay.hide();
          return v?.copyWith(guest: isGuest);
        });
      }
    }
    return null;
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
      final r1 = await _dio.get(
        _apiInfo,
        options: Options(
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
      final r = await _dio.get(
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
}

final platChaoxing = ChaoxingPlatform();
