import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/registry/school.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:punklorde/module/model/school.dart';
import 'package:punklorde/module/model/vault.dart';
import 'package:punklorde/module/service/vault/vault.dart';
import 'package:punklorde/module/service/vault/vault_dialog.dart';
import 'package:punklorde/utils/etc/fdialog.dart';

/// 密码保管库页面
class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    if (vaultService.lockEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ok = await ensureVaultAuth(context);
        if (mounted) setState(() => _authed = ok);
      });
    }
  }

  Future<void> _unlock() async {
    final ok = await ensureVaultAuth(context);
    if (mounted) setState(() => _authed = ok);
  }

  bool get _needAuth => vaultService.lockEnabled && !_authed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.setting.password_vault),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
              suffixes: [
                FHeaderAction(
                  icon: const Icon(LucideIcons.settings2),
                  onPress: _openSettings,
                ),
                FHeaderAction(
                  icon: const Icon(LucideIcons.plus),
                  onPress: () => _openEditor(null),
                ),
              ],
            ),
            Expanded(
              child: _needAuth
                  ? _buildLockedView(colors)
                  : _buildEntries(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedView(FColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(LucideIcons.lockKeyhole, color: colors.primary, size: 40),
            const SizedBox(height: 8),
            Text(
              t.vault.locked,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              t.vault.locked_hint,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FButton(
              variant: .primary,
              onPress: _unlock,
              child: Text(t.vault.unlock),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntries(FColors colors) {
    return FutureBuilder<List<VaultEntry>>(
      future: vaultService.entries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(LucideIcons.vault, color: colors.primary, size: 32),
                Text(
                  t.vault.empty,
                  style: TextStyle(fontSize: 18, color: colors.mutedForeground),
                ),
                Text(
                  t.vault.empty_hint,
                  style: TextStyle(fontSize: 13, color: colors.mutedForeground),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final grouped = <String, List<VaultEntry>>{};
        for (final entry in entries) {
          grouped.putIfAbsent(entry.schoolId, () => []).add(entry);
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: colors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final schoolId in grouped.keys)
                FTileGroup(
                  label: Text(_schoolName(schoolId)),
                  children: [
                    for (final entry in grouped[schoolId]!)
                      FTile(
                        title: Text(entry.username),
                        subtitle: Text(
                          vaultAccountTypeName(entry.accountType, context),
                        ),
                        details: (entry.remark == null)
                            ? null
                            : Text(
                                entry.remark!,
                                style: const TextStyle(fontSize: 12),
                              ),
                        suffix: const Icon(LucideIcons.chevronRight),
                        onPress: () => _openEditor(entry),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  String _schoolName(String schoolId) {
    return getSchool(schoolId)?.name ?? schoolId;
  }

  Future<void> _openEditor(VaultEntry? entry) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => VaultEditorPage(entry: entry),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => const VaultSettingsPage(),
        fullscreenDialog: true,
      ),
    );
    if (mounted) setState(() {});
  }
}

/// 保管库设置（独立页面）
class VaultSettingsPage extends StatefulWidget {
  const VaultSettingsPage({super.key});

  @override
  State<VaultSettingsPage> createState() => _VaultSettingsPageState();
}

class _VaultSettingsPageState extends State<VaultSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final lockEnabled = vaultService.lockEnabled;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.common.setting),
              prefixes: [
                FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    FTileGroup(
                      label: Text(t.vault.lock),
                      children: [
                        FTile(
                          title: Text(t.vault.set_lock),
                          subtitle: Text(
                            t.vault.locked_hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                          details: FSwitch(
                            value: lockEnabled,
                            onChange: _toggleLock,
                          ),
                        ),
                        FTile(
                          title: Text(t.vault.set_password),
                          subtitle: Text(
                            t.vault.set_password_hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                          details: (vaultService.hasUnlockPassword)
                              ? Icon(LucideIcons.check, color: colors.primary)
                              : null,
                          onPress: _setPassword,
                        ),
                        FTile(
                          title: Text(t.vault.biometric_unlock),
                          subtitle: Text(
                            t.vault.biometric_hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                          details: FSwitch(
                            value: vaultService.biometricEnabled,
                            onChange: _toggleBiometric,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 开关锁：开锁需先设置解锁密码
  Future<void> _toggleLock(bool enable) async {
    if (enable) {
      if (!vaultService.hasUnlockPassword) {
        await _setPassword();
      }
      return;
    }
    await _disableLock();
  }

  Future<void> _setPassword() async {
    // 已设置过密码时，需先通过一次认证（生物认证优先）再修改
    if (vaultService.hasUnlockPassword) {
      final ok = await ensureVaultAuth(context);
      if (!ok || !mounted) return;
    }
    final saved = await showFSheet<bool>(
      context: context,
      builder: (_) => const _SetPasswordSheet(),
      side: .btt,
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // 生物认证必须依赖已设置的解锁密码兜底
      if (!vaultService.hasUnlockPassword) {
        if (mounted) {
          showFToast(
            context: context,
            variant: .destructive,
            alignment: .topCenter,
            title: Text(t.vault.biometric_requires_password),
            duration: const Duration(seconds: 3),
            icon: const Icon(LucideIcons.circleX),
          );
        }
        return;
      }
      if (!await vaultService.biometricAvailable) {
        if (mounted) {
          showFToast(
            context: context,
            variant: .destructive,
            alignment: .topCenter,
            title: Text(t.vault.biometric_unavailable),
            duration: const Duration(seconds: 3),
            icon: const Icon(LucideIcons.circleX),
          );
        }
        return;
      }
      final ok = await vaultService.authenticateBiometric(
        localizedReason: t.vault.biometric_reason,
      );
      if (!ok) return;
      vaultService.setBiometricEnabled(true);
      if (mounted) setState(() {});
      return;
    }
    vaultService.setBiometricEnabled(false);
    if (mounted) setState(() {});
  }

  Future<void> _disableLock() async {
    final ok = await ensureVaultAuth(context);
    if (!ok || !mounted) return;
    final confirmed = await showFDialog(
      context: context,
      builder: (context, style, animation) => punklordeDialog(
        style: style,
        animation: animation,
        title: Text(t.vault.disable_lock),
        body: Text(t.vault.disable_lock_confirm),
        actions: [
          FButton(
            size: .xs,
            onPress: () => Navigator.of(context).pop(false),
            child: Text(t.notice.cancel),
          ),
          FButton(
            size: .xs,
            variant: .destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(t.notice.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vaultService.disableLock();
      if (mounted) setState(() {});
    }
  }
}

/// 条目编辑页
class VaultEditorPage extends StatefulWidget {
  final VaultEntry? entry;

  const VaultEditorPage({super.key, this.entry});

  @override
  State<VaultEditorPage> createState() => _VaultEditorPageState();
}

class _VaultEditorPageState extends State<VaultEditorPage> {
  late final School? _school = getSchool(
    widget.entry?.schoolId ?? currentSchoolSignal.value?.id ?? '',
  );
  late Platform? _platform = (widget.entry != null)
      ? (_school?.platforms[widget.entry!.platformId] ??
            _firstPlatformOf(_school))
      : _firstPlatformOf(_school);
  late final TextEditingController _username = TextEditingController(
    text: widget.entry?.username,
  );
  late final TextEditingController _password = TextEditingController(
    text: widget.entry?.password,
  );
  late final TextEditingController _remark = TextEditingController(
    text: widget.entry?.remark,
  );

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _remark.dispose();
    super.dispose();
  }

  List<Platform> get _platforms => _school?.platforms.values.toList() ?? [];

  Future<void> _selectPlatform() async {
    final list = _platforms;
    if (list.isEmpty) return;
    final selected = await Navigator.of(context).push<Platform>(
      MaterialPageRoute(
        builder: (_) =>
            _PlatformSelectPage(platforms: list, current: _platform),
        fullscreenDialog: true,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _platform = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isEdit = widget.entry != null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(isEdit ? t.vault.edit : t.vault.add),
              prefixes: [
                FHeaderAction.x(onPress: () => Navigator.of(context).pop()),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(label: t.vault.school, value: _school?.name ?? ''),
                    const SizedBox(height: 12),
                    // 平台与账号类型合并显示：选择平台即自动带出其登录账号类型
                    FTappable(
                      onPress: _selectPlatform,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.mutedForeground.withAlpha(10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${t.vault.platform}: '
                                    '${_platform?.name ?? ''}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (_platform != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${t.vault.account_type}: '
                                      '${vaultAccountTypeName(_platform!.loginAccountType, context)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronsUpDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FTextField(
                      control: .managed(controller: _username),
                      label: Text(t.vault.username),
                      hint: t.vault.username,
                    ),
                    const SizedBox(height: 12),
                    FTextField.password(
                      control: .managed(controller: _password),
                      label: Text(t.common.password),
                      hint: t.common.password,
                    ),
                    const SizedBox(height: 12),
                    FTextField(
                      control: .managed(controller: _remark),
                      label: Text(t.vault.remark),
                      hint: t.vault.remark,
                    ),
                    const SizedBox(height: 24),
                    FButton(
                      variant: .primary,
                      onPress: _save,
                      prefix: const Icon(LucideIcons.save),
                      child: Text(t.action.save),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 8),
                      FButton(
                        variant: .destructive,
                        onPress: _delete,
                        prefix: const Icon(LucideIcons.trash2),
                        child: Text(t.vault.delete),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final schoolId = _school?.id ?? '';
    final platform = _platform;
    if (schoolId.isEmpty || platform == null) return;
    final entry = widget.entry;
    final username = _username.text.trim();
    if (username.isEmpty) return;
    if (entry == null) {
      await vaultService.addEntry(
        VaultEntry(
          id: VaultEntry.newId(),
          schoolId: schoolId,
          platformId: platform.id,
          accountType: platform.loginAccountType,
          username: username,
          password: _password.text,
          remark: (_remark.text.isEmpty) ? null : _remark.text,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await vaultService.updateEntry(
        entry.copyWith(
          platformId: platform.id,
          username: username,
          password: _password.text,
          remark: (_remark.text.isEmpty) ? null : _remark.text,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;
    final confirmed = await showFDialog(
      context: context,
      builder: (context, style, animation) => punklordeDialog(
        style: style,
        animation: animation,
        title: Text(t.vault.delete),
        body: Text(t.vault.delete_confirm),
        actions: [
          FButton(
            size: .xs,
            onPress: () => Navigator.of(context).pop(false),
            child: Text(t.notice.cancel),
          ),
          FButton(
            size: .xs,
            variant: .destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(t.notice.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vaultService.removeEntry(entry.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }
}

/// 平台选择页
class _PlatformSelectPage extends StatelessWidget {
  final List<Platform> platforms;
  final Platform? current;

  const _PlatformSelectPage({required this.platforms, this.current});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.vault.platform),
              prefixes: [
                FHeaderAction.x(onPress: () => Navigator.of(context).pop()),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FTileGroup(
                    children: [
                      for (final platform in platforms)
                        FTile(
                          title: Text(platform.name),
                          subtitle: Text(
                            vaultAccountTypeName(
                              platform.loginAccountType,
                              context,
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          details: (platform.id == current?.id)
                              ? Icon(
                                  LucideIcons.check,
                                  color: context.theme.colors.primary,
                                )
                              : null,
                          onPress: () => Navigator.of(context).pop(platform),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 取学校的第一个平台
Platform? _firstPlatformOf(School? school) {
  final values = school?.platforms.values.toList() ?? [];
  return (values.isEmpty) ? null : values.first;
}

/// 只读信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.mutedForeground.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: colors.mutedForeground),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置解锁密码面板（与登录面板同布局）
class _SetPasswordSheet extends StatefulWidget {
  const _SetPasswordSheet();

  @override
  State<_SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends State<_SetPasswordSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _mismatch = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => _mismatch = true);
      return;
    }
    final navigator = Navigator.of(context);
    await vaultService.setUnlockPassword(_passwordController.text);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
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
                      t.vault.set_password,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: .bold,
                        color: colors.foreground,
                      ),
                    ),
                    Text(
                      t.vault.setup_hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    FTextField.password(
                      control: .managed(controller: _passwordController),
                      label: Text(t.vault.set_password),
                      hint: t.vault.set_password,
                    ),
                    FTextField.password(
                      control: .managed(controller: _confirmController),
                      label: Text(t.vault.confirm_password),
                      error: (_mismatch)
                          ? Text(t.vault.password_mismatch)
                          : null,
                      hint: t.vault.confirm_password,
                    ),
                    const FDivider(),
                    const SizedBox(height: 8),
                    FButton(
                      variant: .primary,
                      onPress: _submit,
                      child: Text(t.notice.confirm),
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
