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
import 'package:punklorde/module/network/interceptor/cqupt.dart';
import 'package:punklorde/module/platform/cqupt/base/unify.dart';
import 'package:punklorde/utils/ua.dart';

class CquptAcademicPortalPlatform extends Platform {
  static const String _domainLogin =
      "http://jwzx.cqupt.edu.cn/tysfrz/index.php";
  String _apiInfo(String uid) =>
      "https://sport.cqupt.edu.cn/new_wxapp/wxUnifyId/getUserInfo?unifyId=$uid&studentNo=1";
  static const String _apiTest =
      "http://jwzx.cqupt.edu.cn/kebiao/kb_stuList.php?jxb=0";

  @override
  String get id => "cqupt_academic_portal";

  @override
  String get name => "教务在线";

  @override
  String get descript => "用于课表、考试等信息查询";

  late final Dio _dio;

  late final CquptUnifyBasePlatform _unifyBasePlatform;

  CquptAcademicPortalPlatform() {
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {"User-Agent": UAUtil.getUA(.raw)},
        validateStatus: (status) => status != null && status < 500,
      ),
    )..interceptors.add(CquptForwardInterceptor());
    _unifyBasePlatform = CquptUnifyBasePlatform();
  }

  Future<AuthCredential?> _login(String uid, String pwd, bool longTerm) async {
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

    await _dio.get(
      url1,
      options: Options(
        followRedirects: true,
        headers: {
          "User-Agent": UAUtil.getUA(.raw),
          "Cookie": "PHPSESSID=$ticket",
        },
      ),
    );

    if (ticket == null) return null;
    final r1 = await _dio.get(_apiInfo(uid));
    if (r1.statusCode != 200 ||
        r1.data["code"] != "10200" ||
        r1.data["data"] == null) {
      return null;
    }
    final String? stuId = r1.data["data"]["studentNo"];
    final String? username = r1.data["data"]["username"];
    final int? grade = int.tryParse(r1.data["data"]["grade"]);
    final bool sex = r1.data["data"]["sex"] == "1";

    if (stuId == null || username == null || grade == null) return null;

    return AuthCredential(
      guest: false,
      type: id,
      id: stuId,
      name: username,
      token: ticket,
      expireAt: DateTime.now().addMinutes(30),
      ext: {
        "unify_id": uid,
        "grade": grade,
        "sex": sex,
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

      await _dio.get(
        url1,
        options: Options(
          followRedirects: true,
          headers: {
            "User-Agent": UAUtil.getUA(.raw),
            "Cookie": "PHPSESSID=$ticket",
          },
        ),
      );
      if (ticket == null) return null;
      return credential.copyWith(
        token: ticket,
        expireAt: DateTime.now().addMinutes(30),
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
    try {
      final r1 = await _dio.get(
        _apiTest,
        options: Options(
          headers: {
            "User-Agent": UAUtil.getUA(.raw),
            "Cookie": "PHPSESSID=${credential.token}",
          },
        ),
      );
      return r1.data is String && (r1.data as String).contains("<body>");
    } catch (e) {
      return false;
    }
  }
}

final platCquptAcademicPortal = CquptAcademicPortalPlatform();
