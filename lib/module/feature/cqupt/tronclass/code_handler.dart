import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/service.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/utils/link_parse.dart';
import 'package:punklorde/module/model/code_handler.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';
import 'package:toastification/toastification.dart';

/// 学在重邮签到
class CquptTronCheckinCodeHandler extends CodeHandler {
  @override
  String get id => "cqupt:tronclass:checkin";

  @override
  String get name => "学在重邮签到";

  @override
  bool get immediatelyRedirect => true;

  @override
  Future<void> handle(context, data) async {
    final credentilas = checkinAuthSignal.value
        .toList()
        .where((v) => v.type == platCquptTronclass.id)
        .toList();
    final result = TronClassSignDecoder.decode(data);

    if (credentilas.isEmpty) {
      toastification.show(
        context: context,
        title: Text(t.notice.unselected_user),
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
        primaryColor: Colors.red,
        icon: const Icon(LucideIcons.circleX),
      );
      return;
    }

    if (result == null ||
        result.isEmpty ||
        result["data"] == null ||
        result["rollcallId"] == null) {
      toastification.show(
        context: context,
        title: Text(t.notice.invalid_qr_code),
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
        primaryColor: Colors.red,
        icon: const Icon(LucideIcons.circleX),
      );
      return;
    }

    await serviceCquptTronCheckin.checkinQr(
      context,
      credentilas,
      result["rollcallId"].toString(),
      result["data"],
    );
  }

  @override
  bool match(data) {
    return (data is String && data.startsWith("/j?p="));
  }
}

final handlerCquptTronCheckin = CquptTronCheckinCodeHandler();
