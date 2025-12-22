import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:punklorde/common/models/auth.dart';

class TronclassCquptAuthProvider extends AccountProvider {
  @override
  String get id => "tronclass_cqupt";

  @override
  String get name => "学在重邮";

  @override
  List<AccountInputSchema>? get inputSchema => null;

  @override
  String? get uiRoute => "";

  @override
  Future<AuthCredential?> login(
    BuildContext context,
    Map<String, dynamic> param,
  ) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<bool> logout(AuthCredential auth) {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  Future<AuthCredential?> refresh(AuthCredential auth) {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  bool get reqireUi => true;

  @override
  bool get supportRefresh => true;
}
