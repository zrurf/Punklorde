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
import 'package:punklorde/module/platform/cqupt/interceptor/sport_portal.dart';
import 'package:punklorde/utils/ua.dart';

class CquptSportPortalPlatform extends Platform {
  static const String _domain = "172.20.2.228";
  static const String _baseUrl = "http://$_domain";
  static const String _domainLogin = "$_baseUrl/portal/pages/casLogin/index";
  static const String _apiLogin = "$_baseUrl/api/oauth/fs/sys/login";
  static const String _apiInfo = "$_baseUrl/api/oauth/getUserInfo";

  @override
  String get id => "cqupt_sport_portal";

  @override
  String get name => "智慧体育门户";

  @override
  String get descript => "用于校园跑记录获取、申诉（需连接学校VPN使用）";

  late final Dio _dio;

  late final CquptSportPortalInterceptor _interceptor;

  late final CquptUnifyBasePlatform _unifyBasePlatform;

  CquptSportPortalPlatform() {
    _interceptor = CquptSportPortalInterceptor();
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {"User-Agent": UAUtil.getUA(.raw)},
        validateStatus: (status) => status != null && status < 500,
      ),
    )..interceptors.add(_interceptor);
    _unifyBasePlatform = CquptUnifyBasePlatform();
  }

  Future<AuthCredential?> _login(String uid, String pwd, bool longTerm) async {
    _interceptor.setToken(null);
    final CookieJar cookieJar = CookieJar();
    final url1 = await _unifyBasePlatform.passwordLogin(
      _domainLogin,
      uid,
      pwd,
      longTerm,
      cookieJar,
    );
    if (url1 == null) return null;
    final uri1 = Uri.parse(url1);
    final ticket = uri1.queryParameters["ticket"];
    if (ticket == null) return null;
    final r1 = await _dio.post(
      _apiLogin,
      options: Options(
        headers: {"User-Agent": UAUtil.getUA(.raw), "Referer": url1},
        contentType: Headers.jsonContentType,
      ),
      data: {"ticket": ticket},
    );
    if (r1.statusCode != 200 ||
        r1.data["code"] != "10200" ||
        r1.data["data"] == null) {
      return null;
    }

    final String? accessTk = r1.data["data"]["access_token"]?.toString();
    final String? refreshTk = r1.data["data"]["refresh_token"]?.toString();
    final String? tokenType = r1.data["data"]["token_type"]?.toString();
    final num? expiresIn = r1.data["data"]["expires_in"];
    if (accessTk == null ||
        refreshTk == null ||
        tokenType == null ||
        expiresIn == null) {
      return null;
    }
    _interceptor.setToken(accessTk);
    final r2 = await _dio.get(
      _apiInfo,
      options: Options(
        headers: {"User-Agent": UAUtil.getUA(.raw), "Referer": url1},
      ),
    );
    if (r2.statusCode != 200 ||
        r2.data["code"] != "10200" ||
        r2.data["data"] == null) {
      return null;
    }
    final String? uuid = r2.data["data"]["id"]?.toString();
    final String? uname = r2.data["data"]["realName"]?.toString();
    final String? avatar = r2.data["data"]["avatar"]?.toString();
    if (uuid == null || uname == null || avatar == null) return null;
    return AuthCredential(
      guest: false,
      type: id,
      id: uuid,
      name: uname,
      token: accessTk,
      expireAt: DateTime.now().addSeconds(expiresIn.toInt()),
      ext: {
        "uid": uid,
        "refresh": refreshTk,
        "token_type": tokenType,
        "avatar": avatar,
        "cookie": await serializeCookieJar(
          cookieJar,
          CquptUnifyBasePlatform.cookieDomain,
        ),
      },
    );
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
      final url1 = await _unifyBasePlatform.refresh(_domainLogin, cookie);
      if (url1 == null) return null;
      final uri1 = Uri.parse(url1);
      final ticket = uri1.queryParameters["ticket"];
      if (ticket == null) return null;
      final r1 = await _dio.post(
        _apiLogin,
        options: Options(
          headers: {"User-Agent": UAUtil.getUA(.raw), "Referer": url1},
          contentType: Headers.jsonContentType,
        ),
        data: {"ticket": ticket},
      );
      if (r1.statusCode != 200 ||
          r1.data["code"] != "10200" ||
          r1.data["data"] == null) {
        return null;
      }
      final String? accessTk = r1.data["data"]["access_token"]?.toString();
      final String? refreshTk = r1.data["data"]["refresh_token"]?.toString();
      final String? tokenType = r1.data["data"]["token_type"]?.toString();
      final num? expiresIn = r1.data["data"]["expires_in"];
      if (accessTk == null ||
          refreshTk == null ||
          tokenType == null ||
          expiresIn == null) {
        return null;
      }
      final ext = credential.ext ?? {};
      ext["refresh"] = refreshTk;
      ext["token_type"] = tokenType;
      ext["cookie"] = await serializeCookieJar(
        cookie,
        CquptUnifyBasePlatform.cookieDomain,
      );
      return credential.copyWith(
        token: accessTk,
        expireAt: DateTime.now().addSeconds(expiresIn.toInt()),
        ext: ext,
      );
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  @override
  Future<AuthCredential?> login(BuildContext context, bool isGuest) async {
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
            isPwd: false,
            defaultValue: '',
            hint: t.common.unify_id,
          ),
          LoginInputEntry(
            id: "pwd",
            lable: t.common.password,
            isPwd: true,
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
        return v?.copyWith(guest: isGuest);
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
    _interceptor.setToken(credential.token);
    try {
      final r1 = await _dio.get(
        _apiInfo,
        options: Options(
          headers: {"User-Agent": UAUtil.getUA(.raw), "Referer": _baseUrl},
        ),
      );
      return !(r1.statusCode != 200 ||
          r1.data["code"] != "10200" ||
          r1.data["data"] == null);
    } catch (e) {
      return false;
    }
  }
}

final platCquptSportPortal = CquptSportPortalPlatform();
