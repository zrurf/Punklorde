import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:punklorde/common/models/auth.dart';
import 'package:punklorde/common/utils/etc/device.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/const/url.dart';

class ModTongtianAuth {
  String? openid;
  String token;
  String publicKey;

  ModTongtianAuth({required this.token, required this.publicKey});

  factory ModTongtianAuth.fromJson(Map<String, dynamic> json) {
    return ModTongtianAuth(token: json['token'], publicKey: json['publicKey']);
  }
}

class TongtianAuthProvider extends AccountProvider {
  @override
  final String id = "tongtian";
  @override
  final String name = "同天智障体育";

  @override
  List<AccountInputSchema>? get inputSchema => [
    AccountInputSchema(
      id: "openid",
      lable: "Open ID",
      hint: "输入由微信抓包得到的Open ID",
    ),
  ];

  @override
  bool get reqireUi => false;

  @override
  bool get supportRefresh => true;

  @override
  String? get uiRoute => null;

  final _dio = Dio();

  @override
  Future<AuthCredential?> refresh(AuthCredential auth) async {
    var newAuth = await _getAuth(auth.id);
    return (newAuth != null)
        ? AuthCredential(
            type: id,
            id: auth.id,
            token: newAuth.token,
            ext: {"publicKey": newAuth.publicKey},
          )
        : null;
  }

  @override
  Future<AuthCredential?> login(
    BuildContext context,
    Map<String, dynamic> param,
  ) async {
    var auth = await _getAuth(param["openid"] as String);
    return (auth != null)
        ? AuthCredential(
            type: id,
            id: param["openid"],
            token: auth.token,
            ext: {"publicKey": auth.publicKey},
          )
        : null;
  }

  @override
  Future<bool> logout(AuthCredential auth) async {
    return true;
  }

  Future<ModTongtianAuth?> _getAuth(String openid) async {
    try {
      final response = await _dio.get(
        '$loginUrl?sxCode=&openid=$openid&phoneType=${deviceModel}_$deviceOs',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": getUA(.wxapplet),
          },
        ),
      );
      return ModTongtianAuth.fromJson(response.data["data"]);
    } catch (e) {
      return null;
    }
  }
}
