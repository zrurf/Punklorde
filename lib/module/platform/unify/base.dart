import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart';
import 'package:nanoid_plus/nanoid_plus.dart';
import 'package:punklorde/utils/ua.dart';

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

/// 二次认证参数（从 reAuth 页面动态下发的 reAuthParams 中解析）
class UnifyReAuthParam {
  final String reAuthType; // 认证方式（2=密码 3=短信 10=OTP 等）
  final String service; // 认证的服务地址
  final String isMultifactor;
  final String? pwdEncryptSalt; // 密码加密盐
  final String? reAuthUserId; // 用户名

  const UnifyReAuthParam({
    required this.reAuthType,
    required this.service,
    required this.isMultifactor,
    this.pwdEncryptSalt,
    this.reAuthUserId,
  });
}

/// 统一认证平台基类（各校核心登录算法一致，仅域名与二次认证不同）
abstract class UnifyBasePlatform {
  late final Dio _dio;
  late final Nanoid _nanoid;
  late final AesCbc _crypto;

  /// 认证服务器前缀，例如 https://ids.cqupt.edu.cn/authserver
  String get serverPrefix;

  /// Cookie 域集合
  Set<String> get cookieDomains;

  /// 是否支持二次认证（重邮不支持，中传支持）
  bool get supportReAuth => false;

  UnifyBasePlatform({List<Interceptor> interceptors = const []}) {
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
    )..interceptors.addAll(interceptors);
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

  /// 登录后处理 302 跳转，返回携带 ST 的重定向地址
  /// 启用二次认证的学校会在此处完成 reAuth 流程
  Future<String?> _resolveLocation(
    Response loginResp,
    CookieJar cookieJar, {
    Future<Map<String, String>?> Function(UnifyReAuthParam param)? onReAuth,
  }) async {
    var location = loginResp.headers["location"]?.first;
    if (location == null || location.isEmpty) return null;
    if (supportReAuth && location.contains('/reAuthCheck/')) {
      if (onReAuth == null) return null;
      final fullUrl = location.startsWith('http')
          ? location
          : '$serverPrefix$location';
      final pageResp = await _dio.getUri(Uri.parse(fullUrl));
      final param = parseReAuthParam(pageResp.data as String? ?? '');
      if (param == null) return null;
      final submit = await onReAuth(param);
      if (submit == null) return null;
      final r = await _dio.post(
        '$serverPrefix/reAuthCheck/reAuthSubmit.do',
        data: FormData.fromMap(submit),
      );
      if (r.statusCode != 200) return null;
      // 认证成功后重走登录流程签发 ST
      final loginUrl =
          '$serverPrefix/login?service=${Uri.encodeComponent(param.service)}';
      final r2 = await _dio.getUri(Uri.parse(loginUrl));
      if (!(const [302, 303]).contains(r2.statusCode)) return null;
      location = r2.headers["location"]?.first;
    }
    return location;
  }

  /// 从二次认证页面 HTML 中解析动态下发的 reAuthParams
  UnifyReAuthParam? parseReAuthParam(String html) {
    final match = RegExp(
      r'reAuthParams\s*=\s*(\{.*?\});',
      dotAll: true,
    ).firstMatch(html);
    if (match == null) return null;
    try {
      final map = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      return UnifyReAuthParam(
        reAuthType: map['reAuthType']?.toString() ?? '',
        service: map['service']?.toString() ?? '',
        isMultifactor: map['isMultifactor']?.toString() ?? 'true',
        pwdEncryptSalt: map['pwdEncryptSalt']?.toString(),
        reAuthUserId: map['reAuthUserId']?.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取二次认证动态验证码
  ///
  /// 返回可再次发送的倒计时秒数（对应 reAuth.js 的 codeTime）；失败返回 null。
  Future<int?> sendReAuthDynamicCode(
    String userName,
    String authCodeTypeName,
    CookieJar cookieJar,
  ) async {
    final CookieManager cookieManager = CookieManager(
      cookieJar,
      ignoreInvalidCookies: true,
    );
    _dio.interceptors.add(cookieManager);
    try {
      final r = await _dio.post(
        '$serverPrefix/dynamicCode/getDynamicCodeByReauth.do',
        data: FormData.fromMap({
          'userName': userName,
          'authCodeTypeName': authCodeTypeName,
        }),
      );
      Object? body = r.data;
      if (body is String) {
        // 服务端未声明 JSON Content-Type 时 dio 不会自动反序列化
        try {
          body = jsonDecode(body);
        } catch (_) {
          return null;
        }
      }
      if (r.statusCode != 200 || body is! Map) return null;
      final data = body;
      switch (data['res']?.toString()) {
        case 'success':
          final t = int.tryParse('${data['codeTime']}');
          return (t != null && t > 0) ? t : 60;
        case 'wechat_success':
        case 'cpdaily_success':
          // 微信/今日校园渠道服务端不返回 codeTime，与官方页面一致固定 120s
          return 120;
        default:
          return null;
      }
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 密码登录
  Future<String?> passwordLogin(
    String url,
    String user,
    String pwd,
    bool longTerm,
    CookieJar cookieJar, {
    Future<Map<String, String>?> Function(UnifyReAuthParam param)? onReAuth,
  }) async {
    // 忽略无效 cookie：CAS 会下发空值 cookie（如 CLIENT_URL=），避免解析崩溃
    final CookieManager cookieManager = CookieManager(
      cookieJar,
      ignoreInvalidCookies: true,
    );
    _dio.interceptors.add(cookieManager);
    try {
      final String url1 =
          "$serverPrefix/login?service=${Uri.encodeComponent(url)}";
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

      return await _resolveLocation(response2, cookieJar, onReAuth: onReAuth);
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 刷新登录
  Future<String?> refresh(String url, CookieJar cookieJar) async {
    final CookieManager cookieManager = CookieManager(
      cookieJar,
      ignoreInvalidCookies: true,
    );
    _dio.interceptors.add(cookieManager);
    try {
      final String url1 =
          "$serverPrefix/login?service=${Uri.encodeComponent(url)}";
      final response1 = await _dio.get(url1);
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
