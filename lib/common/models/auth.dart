import 'package:flutter/widgets.dart';

// 身份验证凭证
class AuthCredential {
  final String type;
  final String id;
  final String token;
  final String? refreshToken;
  final Map<String, dynamic> ext;

  const AuthCredential({
    required this.type,
    required this.id,
    required this.token,
    this.refreshToken,
    this.ext = const {},
  });

  Map<String, dynamic> toJson() => {
    "type": type,
    "id": id,
    "token": token,
    "refresh_token": refreshToken,
    "ext": ext,
  };

  factory AuthCredential.fromJson(Map<String, dynamic> json) => AuthCredential(
    type: json['type'] as String,
    id: json['id'] as String,
    token: json['token'] as String,
    refreshToken: json['refresh_token'] as String?,
    ext: Map<String, dynamic>.from(json['ext'] as Map? ?? {}),
  );
}

// 访客身份验证凭证
class GuestAuthCredential {
  final String id;
  final String name;
  final AuthCredential auth;

  const GuestAuthCredential({
    required this.id,
    required this.name,
    required this.auth,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "auth": auth.toJson(),
  };

  factory GuestAuthCredential.fromJson(Map<String, dynamic> json) =>
      GuestAuthCredential(
        id: json['id'] as String,
        name: json['name'] as String,
        auth: AuthCredential.fromJson(json['auth'] as Map<String, dynamic>),
      );
}

// 身份验证提供者
abstract class AccountProvider {
  String get id;
  String get name;

  bool get supportRefresh; // 是否支持刷新（会在App启动时自动刷新）
  bool get reqireUi; // 是否需要UI

  String? get uiRoute; // 如果需要UI登录方式，则需要提供UI路由
  List<AccountInputSchema>? get inputSchema; // 如果不支持UI登录方式，则需要提供输入参数

  Future<AuthCredential?> login(
    BuildContext context,
    Map<String, dynamic> param,
  );
  Future<bool> logout(AuthCredential auth);
  Future<AuthCredential?> refresh(AuthCredential auth);
}

class AccountInputSchema {
  final String id;
  final String lable;
  final bool hidden;
  final RegExp? pattern;
  final String? defaultValue;
  final String? hint;
  final String? desc;

  const AccountInputSchema({
    required this.id,
    required this.lable,
    this.hidden = false,
    this.pattern,
    this.defaultValue,
    this.hint,
    this.desc,
  });
}
