import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/module/feature/chaoxing/api/client.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:punklorde/module/service/lbs/location.dart';

/// 处理签到卡片点击
Future<void> handleSignIn(BuildContext context, ActiveResult active) async {
  final otherId = active.otherId;
  switch (otherId) {
    case "2": // 二维码签到
      if (context.mounted) {
        context.push("/p/universal_scan");
      }
    case "5": // 签到码签到
      final code = await _showCodeSheet(context, active);
      if (code != null && code.isNotEmpty && context.mounted) {
        await _doCodeCheckin(context, active.id.toString(), code);
      }
    case "4": // 位置签到
      final pos = await _showPosSheet(context, active);
      if (pos != null && context.mounted) {
        await _doPosCheckin(context, active.id.toString(), pos);
      }
    case "3": // 手势签到
      final confirmed = await _showConfirmSheet(context, active, '手势签到');
      if (confirmed == true && context.mounted) {
        await _doNormalCheckin(context, active.id.toString());
      }
    default: // 普通签到 (otherId "0" 或 null)
      final confirmed = await _showConfirmSheet(context, active, '普通签到');
      if (confirmed == true && context.mounted) {
        await _doNormalCheckin(context, active.id.toString());
      }
  }
}

/// 处理通知卡片点击：提取 idCode，构造 URL 并打开 webview_page
void handleNotification(BuildContext context, ActiveResult active) {
  final contentStr = active.content;
  if (contentStr == null || contentStr.isEmpty) return;

  try {
    final contentJson = json.decode(contentStr) as Map<String, dynamic>;
    final idCode = contentJson['idCode'] as String?;
    if (idCode == null || idCode.isEmpty) return;

    final url = 'https://sharewh3.xuexi365.com/share/$idCode?t=4';
    if (context.mounted) {
      context.push('/feat/chaoxing/webview', extra: url);
    }
  } catch (_) {
    // content 解析失败，忽略
  }
}

// ===== FSheet Helpers =====

Future<String?> _showCodeSheet(
  BuildContext context,
  ActiveResult active,
) async {
  final completer = Completer<String?>();
  String value = "";

  await showFSheet(
    context: context,
    builder: (sheetContext) => Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '签到码签到',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  Text(
                    active.title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  if (active.description != null &&
                      active.description!.isNotEmpty)
                    Text(
                      active.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  const FDivider(),
                  FTextField(
                    control: FTextFieldControl.managed(
                      onChange: (v) => value = v.text,
                    ),
                    label: const Text('签到码'),
                    hint: '请输入签到码',
                  ),
                  const FDivider(),
                  const SizedBox(height: 8),
                  FButton(
                    variant: FButtonVariant.primary,
                    onPress: () {
                      Navigator.of(sheetContext).pop();
                      if (!completer.isCompleted) {
                        completer.complete(value);
                      }
                    },
                    child: const Text('确认签到'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    side: .btt,
  );
  return completer.future;
}

Future<Coordinate?> _showPosSheet(
  BuildContext context,
  ActiveResult active,
) async {
  final completer = Completer<Coordinate?>();
  startLocationService(LocationServiceOptions());

  await showFSheet(
    context: context,
    builder: (sheetContext) => Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '位置签到',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  Text(
                    active.title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  if (active.description != null &&
                      active.description!.isNotEmpty)
                    Text(
                      active.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  const FDivider(),
                  const SizedBox(height: 8),
                  FButton(
                    variant: FButtonVariant.primary,
                    onPress: () {
                      Navigator.of(sheetContext).pop();
                      if (!completer.isCompleted) {
                        stopLocationService();
                        completer.complete(
                          Coordinate(lat: rawLat.value, lng: rawLng.value),
                        );
                      }
                    },
                    prefix: const Icon(LucideIcons.locateFixed),
                    child: const Text('使用当前位置签到'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    side: .btt,
  );

  stopLocationService();
  return completer.future;
}

Future<bool?> _showConfirmSheet(
  BuildContext context,
  ActiveResult active,
  String typeLabel,
) async {
  final completer = Completer<bool?>();

  await showFSheet(
    context: context,
    builder: (sheetContext) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  Text(
                    active.title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  if (active.description != null &&
                      active.description!.isNotEmpty)
                    Text(
                      active.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  const FDivider(),
                  const SizedBox(height: 8),
                  FButton(
                    variant: FButtonVariant.primary,
                    onPress: () {
                      Navigator.of(sheetContext).pop();
                      if (!completer.isCompleted) {
                        completer.complete(true);
                      }
                    },
                    child: const Text('确认签到'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    side: .btt,
  );
  return completer.future;
}

// ===== API Calls =====

Future<void> _doCodeCheckin(
  BuildContext context,
  String activeId,
  String code,
) async {
  final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
  if (cred == null) return;

  final cache = await AuthCredentialCache.fromCredential(cred);
  final api = ApiClient();
  final results = await api.checkinAllCode([cache], activeId, code);
  if (context.mounted) {
    _showResult(context, results);
  }
}

Future<void> _doPosCheckin(
  BuildContext context,
  String activeId,
  Coordinate pos,
) async {
  final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
  if (cred == null) return;

  final cache = await AuthCredentialCache.fromCredential(cred);
  final api = ApiClient();
  final results = await api.checkinAllPos([cache], activeId, pos);
  if (context.mounted) {
    _showResult(context, results);
  }
}

Future<void> _doNormalCheckin(BuildContext context, String activeId) async {
  final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
  if (cred == null) return;

  final cache = await AuthCredentialCache.fromCredential(cred);
  final api = ApiClient();
  final results = await api.checkinAllNormal([cache], activeId);
  if (context.mounted) {
    _showResult(context, results);
  }
}

void _showResult(BuildContext context, List<bool> results) {
  final success = results.isNotEmpty && results.every((e) => e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success ? '签到成功' : '签到失败'),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
    ),
  );
}
