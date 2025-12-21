import 'package:flutter/src/widgets/framework.dart';
import 'package:punklorde/common/models/auth.dart';

class TronclassCquptAuthProvider extends AccountProvider {
  @override
  String get id => "tronclass_cqupt";

  @override
  String get name => "学在重邮";

  @override
  List<AccountInputSchema>? get inputSchema => throw UnimplementedError();

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
  // TODO: implement reqireUi
  bool get reqireUi => throw UnimplementedError();

  @override
  // TODO: implement supportRefresh
  bool get supportRefresh => throw UnimplementedError();
}
