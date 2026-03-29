import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:punklorde/core/account/view/page/guest_add.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/code_handler.dart';
import 'package:punklorde/utils/etc/byte.dart';

class GuestAccountCodeHandler extends CodeHandler {
  @override
  String get id => 'pkld:guest_account';

  @override
  String get name => "访客账号登录";

  @override
  bool get immediatelyRedirect => true;

  @override
  bool match(dynamic data) {
    if (data is DecodedBarcodeBytes) {
      return startsWith(data.bytes, shareDataMagicNum);
    }
    return false;
  }

  @override
  Future<void> handle(context, data) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GuestAddPage(data: data)));
  }
}

final handlerGuestAccount = GuestAccountCodeHandler();
