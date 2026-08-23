import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/registry/school.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/vault.dart';
import 'package:punklorde/module/service/vault/vault.dart';
import 'package:punklorde/utils/etc/fdialog.dart';

/// 账号类型显示名
String vaultAccountTypeName(String accountType, BuildContext context) {
  for (final school in getSchools()) {
    for (final plat in school.platforms.values) {
      if (plat.loginAccountType == accountType) {
        if (accountType == plat.id) return plat.name;
        return '${school.name} ${t.vault.account_type_unify}';
      }
    }
  }
  return accountType;
}

/// 认证视图（锁开启时每次进入保管库/填充前使用）
class VaultAuthView extends StatefulWidget {
  final void Function(bool success) onResult;

  const VaultAuthView({super.key, required this.onResult});

  @override
  State<VaultAuthView> createState() => _VaultAuthViewState();
}

class _VaultAuthViewState extends State<VaultAuthView> {
  final TextEditingController _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlockByBiometric() async {
    final ok = await vaultService.authenticateBiometric(
      localizedReason: t.vault.biometric_reason,
    );
    widget.onResult(ok);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final canBiometric = vaultService.biometricEnabled;
    return Scaffold(
      // showFSheet 路由层已整体上移避让键盘，内部无需再次 resize
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          height: .infinity,
          width: .infinity,
          decoration: BoxDecoration(
            color: colors.background,
            border: .symmetric(horizontal: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            padding: const .symmetric(horizontal: 16, vertical: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Column(
                  spacing: 8,
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    Text(
                      t.vault.unlock_title,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: .bold,
                        color: colors.foreground,
                      ),
                    ),
                    Text(
                      t.vault.unlock_hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    FTextField.password(
                      control: .managed(controller: _controller),
                      label: Text(t.common.password),
                      error: (_wrong) ? Text(t.vault.wrong_password) : null,
                      hint: t.common.password,
                    ),
                    const FDivider(),
                    const SizedBox(height: 8),
                    FButton(
                      variant: .primary,
                      onPress: () {
                        final ok = vaultService.verifyPassword(
                          _controller.text,
                        );
                        if (!ok) {
                          setState(() => _wrong = true);
                          return;
                        }
                        widget.onResult(true);
                      },
                      child: Text(t.vault.unlock),
                    ),
                    if (canBiometric)
                      FButton(
                        variant: .secondary,
                        prefix: const Icon(LucideIcons.fingerprint),
                        onPress: _unlockByBiometric,
                        child: Text(t.vault.biometric_authenticate),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 锁开启时完成一次认证，通过返回 true
Future<bool> ensureVaultAuth(BuildContext context) async {
  if (!vaultService.lockEnabled) return true;
  if (vaultService.biometricEnabled && await vaultService.biometricAvailable) {
    final ok = await vaultService.authenticateBiometric(
      localizedReason: t.vault.biometric_reason,
    );
    if (ok) return true;
  }
  final completer = Completer<bool>();
  await showFSheet(
    context: context,
    builder: (sheetContext) => VaultAuthView(
      onResult: (success) {
        Navigator.of(sheetContext).pop();
        if (!completer.isCompleted) completer.complete(success);
      },
    ),
    side: .btt,
  );
  return completer.future;
}

/// 登录成功后询问是否保存到保管库
Future<void> showVaultSavePrompt(
  BuildContext context, {
  required String schoolId,
  required String platformId,
  required String accountType,
  required String username,
  required String password,
}) async {
  if (!context.mounted) return;
  final confirmed = await showFDialog(
    context: context,
    builder: (context, style, animation) => punklordeDialog(
      style: style,
      animation: animation,
      title: Text(t.vault.save_prompt_title),
      body: Text(t.vault.save_prompt_hint),
      actions: [
        FButton(
          size: .xs,
          variant: .secondary,
          onPress: () => Navigator.of(context).pop(false),
          child: Text(t.vault.not_save),
        ),
        FButton(
          size: .xs,
          variant: .primary,
          onPress: () => Navigator.of(context).pop(true),
          child: Text(t.vault.save_action),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await vaultService.saveEntry(
      schoolId: schoolId,
      platformId: platformId,
      accountType: accountType,
      username: username,
      password: password,
    );
  }
}

/// 选择保管库条目，无可用条目或取消时返回 null
Future<VaultEntry?> showVaultEntryPicker(
  BuildContext context,
  String accountType,
) async {
  if (!await ensureVaultAuth(context)) return null;
  if (!context.mounted) return null;
  final entries = await vaultService.entriesByAccountType(accountType);
  if (entries.isEmpty) {
    if (context.mounted) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.vault.no_entry),
        duration: const Duration(seconds: 3),
        icon: const Icon(LucideIcons.circleX),
      );
    }
    return null;
  }
  final completer = Completer<VaultEntry?>();
  await showFSheet(
    context: context,
    builder: (sheetContext) => Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.vault.fill_from_vault,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final entry in entries)
                      FTile(
                        title: Text(entry.username),
                        subtitle: Text(
                          '${vaultAccountTypeName(entry.accountType, sheetContext)} ${(entry.remark != null) ? "|  ${entry.remark}" : ""}',
                        ),
                        onPress: () {
                          Navigator.of(sheetContext).pop();
                          if (!completer.isCompleted) completer.complete(entry);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    side: .btt,
  );
  return completer.future;
}
