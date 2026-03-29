import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dart_date/dart_date.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/core/account/view/widget/login_panel.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:punklorde/module/platform/cqupt/base/unify.dart';
import 'package:punklorde/utils/ua.dart';
import 'package:punklorde/utils/uuid.dart';

const String _domainService = "lms.tc.cqupt.edu.cn";
const String _domainCas = "ids.cqupt.edu.cn";
const String _domainRelay = "identity.tc.cqupt.edu.cn";

const String _baseUrl = "http://$_domainService";
const String _apiVerify = "$_baseUrl/statistics/api/user-visits";
const String _apiLogin = "$_baseUrl/login";
const String _apiProfile = "$_baseUrl/api/profile";

class CquptTronclassPlatform extends Platform {
  @override
  String get id => "cqupt_tc";

  @override
  String get name => "学在重邮";

  @override
  String get descript => "用于学在重邮平台签到";

  late final Dio _dio;

  late final CquptUnifyBasePlatform _unifyBasePlatform;

  late final CookieJar _cookieJar;

  CquptTronclassPlatform() {
    _cookieJar = CookieJar();
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {"User-Agent": UAUtil.getUA(.wechat)},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _unifyBasePlatform = CquptUnifyBasePlatform();
  }

  /// 手动跟随重定向
  Future<Response> _followRedirects(
    Response resp,
    bool Function(Response resp) condition,
  ) async {
    const maxRedirects = 10;
    var redirectCount = 0;

    while (redirectCount < maxRedirects) {
      if (condition(resp)) {
        break;
      }

      final location = resp.headers["location"]?.first;
      if (location == null || location.isEmpty) {
        break;
      }

      print('Manual redirect: ${resp.realUri} ->$location');

      resp = await _dio.getUri(Uri.parse(location));
      redirectCount++;
    }
    return resp;
  }

  Future<AuthCredential?> _login(String uid, String pwd, bool longTerm) async {
    await _cookieJar.deleteAll();
    final CookieManager cookieManager = CookieManager(_cookieJar);
    _dio.interceptors.add(cookieManager);
    String? sessionId;
    try {
      final r1 = await _dio.get(_apiLogin);
      final r2 = await _followRedirects(r1, (resp) {
        final location = resp.headers["location"]?.first;
        if (location == null || location.isEmpty) {
          return true;
        }
        final uri = Uri.parse(location);
        return ((resp.realUri.host == _domainService &&
                resp.realUri.path == "/login" &&
                uri.host == _domainService)) ||
            (uri.host == _domainCas);
      });
      final location = r2.headers["location"]?.first;
      if (location == null || location.isEmpty) {
        return null;
      }
      final uri1 = Uri.parse(location);
      switch (uri1.host) {
        case _domainCas:
          final url2 = uri1.queryParameters["service"];
          if (url2 == null) return null;
          final url3 = await _unifyBasePlatform.passwordLogin(
            url2,
            uid,
            pwd,
            longTerm,
            _cookieJar,
          );
          if (url3 == null) return null;
          final r3 = await _dio.get(url3);
          final r4 = await _followRedirects(r3, (resp) {
            return (resp.realUri.host == _domainService &&
                resp.realUri.path == "/login");
          });
          sessionId = r4.headers["X-SESSION-ID"]?.first;
        case _domainService:
          sessionId = r2.headers["X-SESSION-ID"]?.first;
        default:
          return null;
      }
      if (sessionId == null) return null;
      final r5 = await _dio.get(
        _apiProfile,
        options: Options(
          headers: {
            "User-Agent": UAUtil.getUA(.raw),
            "X-SESSION-ID": sessionId,
          },
        ),
      );

      return AuthCredential(
        guest: false,
        type: id,
        id: r5.data["id"].toString(),
        name: r5.data["name"].toString(),
        token: sessionId,
        expireAt: DateTime.now().addDays(1),
        ext: Map.from({
          "uid": uid,
          "uuid": DeterministicUuidUtil.generate(
            "${r5.data["id"].toString()}_$uid",
          ),
          "cookie": await serializeCookieJar(_cookieJar, {
            _baseUrl,
            "http://$_domainRelay",
            "https://$_domainRelay",
            ...CquptUnifyBasePlatform.cookieDomain,
          }),
        }),
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  Future<AuthCredential?> _refresh(AuthCredential credential) async {
    final rawMap = credential.ext!['cookie'] as Map<Object?, Object?>;
    final cookieMap = rawMap.map((key, value) {
      return MapEntry(key.toString(), List<String>.from(value as List));
    });
    final cookie = await deserializeCookieJar(cookieMap);
    final CookieManager cookieManager = CookieManager(cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final r1 = await _dio.get(_apiLogin);
      final r2 = await _followRedirects(r1, (resp) {
        final location = resp.headers["location"]?.first;
        if (location == null || location.isEmpty) {
          return true;
        }
        final uri = Uri.parse(location);
        return (resp.realUri.host == _domainService &&
            resp.realUri.path == "/login" &&
            uri.host == _domainService);
      });
      if (r2.realUri.host != _domainService) return null;
      final sessionId = r2.headers["X-SESSION-ID"]?.first;
      return credential.copyWith(
        token: sessionId,
        expireAt: DateTime.now().addDays(1),
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  @override
  Future<AuthCredential?> login(BuildContext context) async {
    final completer = Completer<Map<String, String>?>();

    await showFSheet(
      context: context,
      builder: (sheetContext) => LoginPanel(
        platform: name,
        desc: descript,
        inputEntries: [
          LoginInputEntry(
            id: "id",
            lable: t.common.unify_id,
            hidden: false,
            defaultValue: '',
            hint: t.common.unify_id,
          ),
          LoginInputEntry(
            id: "pwd",
            lable: t.common.password,
            hidden: true,
            defaultValue: '',
            hint: t.common.password,
          ),
        ],
        onConfirm: (values) {
          Navigator.of(sheetContext).pop();
          if (!completer.isCompleted) {
            completer.complete(values);
          }
        },
      ),
      side: .btt,
    );

    final result = await completer.future;

    if (result != null && result['id'] != null && result['pwd'] != null) {
      if (context.mounted) context.loaderOverlay.show();
      return await _login(result['id']!, result['pwd']!, true).then((v) {
        if (context.mounted) context.loaderOverlay.hide();
        return v;
      });
    }

    return null;
  }

  @override
  Future<void> logout(AuthCredential credential) async {}

  @override
  Future<AuthCredential?> refresh(AuthCredential oldCredential) async {
    return await _refresh(oldCredential);
  }

  @override
  Future<bool> validate(AuthCredential credential) async {
    final resp = await _dio.get(
      _apiVerify,
      options: Options(
        headers: {
          "User-Agent": UAUtil.getUA(.raw),
          "Cookie": "session=${credential.token}",
        },
      ),
    );
    final status = resp.statusCode;
    if (status == null) return false;
    return status >= 200 && status < 300;
  }
}

final platCquptTronclass = CquptTronclassPlatform();
