import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart';
import 'package:nanoid_plus/nanoid_plus.dart';
import 'package:punklorde/module/network/interceptor/cqupt.dart';
import 'package:punklorde/utils/ua.dart';

const String _baseUrl = 'https://ids.cqupt.edu.cn/authserver/login';

const String _charset = 'ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678';

// 登录表单字段
class _DomFields {
  final String execution;
  final String pwdEncryptSalt;
  final String lt;

  const _DomFields({
    required this.execution,
    required this.pwdEncryptSalt,
    required this.lt,
  });
}

/// 重邮统一认证平台基类
class CquptUnifyBasePlatform {
  late final Dio _dio;
  late final Nanoid _nanoid;
  late final AesCbc _crypto;

  static const Set<String> cookieDomain = {
    "https://ids.cqupt.edu.cn",
    "https://ids.cqupt.edu.cn/authserver",
  };

  CquptUnifyBasePlatform() {
    _nanoid = Nanoid();
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "User-Agent": UAUtil.getUA(
            .raw,
            useRealSystem: false,
            targetOS: "windows",
          ),
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(CquptForwardInterceptor());
    _crypto = AesCbc.with128bits(
      macAlgorithm: .empty,
      paddingAlgorithm: .pkcs7,
    );
  }

  /// 获取表单字段
  _DomFields? _getDomFields(String html) {
    final dom = parse(html);
    final form = dom.getElementById('pwdFromId');
    final execution = form
        ?.querySelector('input#execution')
        ?.attributes['value'];
    final pwdEncryptSalt = form
        ?.querySelector('input#pwdEncryptSalt')
        ?.attributes['value'];
    final lt = form?.querySelector('input#lt')?.attributes['value'];

    if (execution == null || pwdEncryptSalt == null || lt == null) {
      return null;
    }
    return _DomFields(
      execution: execution,
      pwdEncryptSalt: pwdEncryptSalt,
      lt: lt,
    );
  }

  /// 密码加密
  Future<String> encodePwd(String pwd, String salt) async {
    final prefix = _nanoid.custom(length: 64, charSet: _charset);
    final iv = _nanoid.custom(length: 16, charSet: _charset);
    final res = await _crypto.encrypt(
      utf8.encode(prefix + pwd),
      secretKey: .new(utf8.encode(salt)),
      nonce: utf8.encode(iv),
    );
    return base64.encode(res.cipherText);
  }

  /// 密码登录
  Future<String?> passwordLogin(
    String url,
    String user,
    String pwd,
    bool longTerm,
    CookieJar cookieJar,
  ) async {
    final CookieManager cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);
    try {
      final String url1 = "$_baseUrl?service=${Uri.encodeComponent(url)}";
      final response1 = await _dio.get(url1);
      if (response1.statusCode != 200 ||
          response1.data == null ||
          response1.data is! String) {
        return null;
      }
      _DomFields? fields = _getDomFields(response1.data);
      if (fields == null) return null;

      final Map<String, String> data = {
        "username": user,
        "password": await encodePwd(pwd, fields.pwdEncryptSalt),
        "captcha": "",
        "_eventId": "submit",
        "cllt": "userNameLogin",
        "dllt": "generalLogin",
        "lt": fields.lt,
        "execution": fields.execution,
      };

      if (longTerm) {
        data["rememberMe"] = "true";
      }

      final response2 = await _dio.post(url1, data: FormData.fromMap(data));

      if (!(const [302, 303]).contains(response2.statusCode)) {
        return null;
      }

      final url2 = response2.headers["location"];
      return url2?.first;
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 刷新登录
  Future<String?> refresh(String url, CookieJar cookieJar) async {
    final CookieManager cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);
    try {
      final String url1 = "$_baseUrl?service=${Uri.encodeComponent(url)}";
      final response1 = await _dio.get(url1);
      print("测试：${response1.requestOptions.headers["cookie"]}");
      if (!(const [302, 303]).contains(response1.statusCode)) {
        return null;
      }
      return response1.headers["location"]?.first;
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }
}
