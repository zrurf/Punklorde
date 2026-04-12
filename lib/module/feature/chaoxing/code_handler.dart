import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/service/checkin.dart';
import 'package:punklorde/module/model/code_handler.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';

/// 学习通签到
class ChaoxingCheckinCodeHandler extends CodeHandler {
  @override
  String get id => "chaoxing:checkin";

  @override
  String get name => "学习通签到";

  @override
  bool get immediatelyRedirect => true;

  @override
  Future<void> handle(context, data) async {
    final credentials = checkinAuthSignal.value
        .toList()
        .map((v) {
          final cred = authCredentials.value[v];
          return (cred?.type == platChaoxing.id) ? cred : null;
        })
        .nonNulls
        .toList();

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

    String? aid;
    String? enc;
    String? enc2;

    try {
      final j = json.decode(data);
      aid = j["activeId"] ?? j["id"];
      enc = j["enc"];
      enc2 = j["enc2"];
    } catch (_) {}

    final uri = Uri.tryParse(data);
    if (uri == null) {
      _showErrorToast(context);
      return;
    } else {
      aid = uri.queryParameters["activeId"];
      if (aid?.isEmpty ?? true) {
        aid = uri.queryParameters["id"];
      }
      enc = uri.queryParameters["enc"];
      enc2 = uri.queryParameters["enc2"];
    }

    if (aid == null || aid.isEmpty || enc == null || enc.isEmpty) {
      _showErrorToast(context);
      return;
    }

    final List<AuthCredentialCache> creds = [];

    for (final c in credentials) {
      creds.add(await AuthCredentialCache.fromCredential(c));
    }

    if (context.mounted) {
      await serviceChaoxingCheckin.checkinQr(
        context,
        creds,
        aid,
        enc,
        enc2 ?? "",
      );
    }
  }

  @override
  bool match(data) {
    try {
      if (data is! String) return false;
      final uri = Uri.parse(data);
      return (uri.host.contains("chaoxing.com") &&
          uri.queryParameters.containsKey("enc"));
    } catch (e) {
      return false;
    }
  }

  void _showErrorToast(BuildContext context) {
    showFToast(
      context: context,
      variant: .destructive,
      alignment: .topCenter,
      title: Text(t.notice.invalid_qr_code),
      duration: const Duration(seconds: 3),
      icon: const Icon(LucideIcons.circleX),
    );
  }
}

final handlerChaoxingCheckin = ChaoxingCheckinCodeHandler();
