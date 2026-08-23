import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/tronclass/config.dart';
import 'package:punklorde/module/feature/tronclass/service.dart';
import 'package:punklorde/module/feature/tronclass/utils/link_parse.dart';
import 'package:punklorde/module/model/code_handler.dart';

/// 畅课签到扫码处理器
class TronclassCheckinCodeHandler extends CodeHandler {
  final TronclassConfig config;
  late final TronclassCheckinService _service = TronclassCheckinService(config);

  TronclassCheckinCodeHandler(this.config);

  @override
  String get id => "${config.platformId}:tronclass:checkin";

  @override
  String get name => "${config.name}签到";

  @override
  bool get immediatelyRedirect => true;

  @override
  Future<void> handle(BuildContext context, dynamic data) async {
    final credentials = checkinAuthSignal.value
        .toList()
        .map((v) {
          final cred = authCredentials.value[v];
          return (cred?.type == config.platformId) ? cred : null;
        })
        .nonNulls
        .toList();
    final result = TronClassSignDecoder.decode(data);

    if (credentials.isEmpty) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.notice.unselected_user),
        duration: const Duration(seconds: 3),
        icon: const Icon(LucideIcons.circleX),
      );
      return;
    }

    if (result == null ||
        result.isEmpty ||
        result["data"] == null ||
        result["rollcallId"] == null) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.notice.invalid_qr_code),
        duration: const Duration(seconds: 3),
        icon: const Icon(LucideIcons.circleX),
      );
      return;
    }

    await _service.checkinQr(
      context,
      credentials,
      result["rollcallId"].toString(),
      result["data"],
    );
  }

  @override
  bool match(data) {
    return (data is String && data.startsWith("/j?p="));
  }
}