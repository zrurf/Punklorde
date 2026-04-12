import 'dart:async';
import 'dart:convert';

import 'package:dart_date/dart_date.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forui/widgets/sheet.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/core/account/view/widget/login_panel.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/network/interceptor/cqupt.dart';
import 'package:punklorde/utils/ua.dart';

import '../../model/platform.dart';

class CquptSportPlatform extends Platform {
  static const String _apiBaseUrl = "https://sport.cqupt.edu.cn/new_wxapp";
  static const String _apiUserInfo = "$_apiBaseUrl/wxUnifyId/getUser";
  String _apiLogin(String openid, String device) =>
      "$_apiBaseUrl/wxUnifyId/checkBinding?wxCode=&openid=$openid&phoneType=$device";

  final Dio _dio = Dio();

  CquptSportPlatform() {
    _dio.interceptors.add(CquptForwardInterceptor());
  }

  @override
  String get id => "cqupt_sport";

  @override
  String get name => "重邮智慧体育";

  @override
  String get descript => "用于校园跑";

  Future<AuthCredential?> _login(String openid) async {
    final loginResponse = await _dio.get(
      _apiLogin(openid, '${deviceBrand}_$deviceOs $deviceOSVersion'),
      options: Options(headers: {"User-Agent": UAUtil.getUA(.wxapplet)}),
    );
    if (loginResponse.data['code'] != "10200" ||
        loginResponse.data['data']['isBind'] != 'true') {
      return null;
    }

    final token = loginResponse.data['data']['token'];

    final userResponse = await _dio.get(
      _apiUserInfo,
      options: Options(
        headers: {"User-Agent": UAUtil.getUA(.wxapplet), "token": token},
      ),
    );

    if (userResponse.data['code'] != "10200") {
      return null;
    }

    return AuthCredential(
      id: openid,
      name: userResponse.data['data']['username'],
      token: token,
      type: id,
      guest: false,
      expireAt: DateTime.now().addDays(1),
      ext: {
        'id': userResponse.data['data']['id'],
        'unifyId': userResponse.data['data']['unifyId'],
        'studentNo': userResponse.data['data']['studentNo'],
        'sex': userResponse.data['data']['sex'] == '1',
        'grade': userResponse.data['data']['grade'],
        'deptName': userResponse.data['data']['deptName'],
        'publicKey': base64.decode(loginResponse.data['data']['publicKey']),
      },
    );
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
            id: "openid",
            lable: t.submodule.cqupt_sport.openid,
            isPwd: false,
            defaultValue: '',
            hint: t.submodule.cqupt_sport.openid_hint,
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

    if (result != null && result['openid'] != null) {
      if (context.mounted) context.loaderOverlay.show();
      return await _login(result['openid']!).then((v) {
        if (context.mounted) context.loaderOverlay.hide();
        return v?.copyWith(guest: isGuest);
      });
    }

    return null;
  }

  @override
  Future<void> logout(AuthCredential credential) async {
    return;
  }

  @override
  Future<AuthCredential?> refresh(AuthCredential oldCredential) async {
    return await _login(oldCredential.id);
  }

  @override
  Future<bool> validate(AuthCredential credential) async {
    final response = await _dio.get(
      _apiUserInfo,
      options: Options(
        headers: {
          "User-Agent": UAUtil.getUA(.wxapplet),
          "token": credential.token,
        },
      ),
    );
    return response.data['code'] == "10200";
  }
}

final platCquptSport = CquptSportPlatform();
