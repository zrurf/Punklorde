import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/service/vault/vault_dialog.dart';

class LoginInputEntry {
  final String id;
  final String lable;
  final bool isPwd;
  final RegExp? pattern;
  final String? defaultValue;
  final String? hint;
  final String? desc;

  const LoginInputEntry({
    required this.id,
    required this.lable,
    this.isPwd = false,
    this.pattern,
    this.defaultValue,
    this.hint,
    this.desc,
  });
}

class LoginPanel extends StatefulWidget {
  final String platform;
  final String desc;
  final List<LoginInputEntry> inputEntries;
  final void Function(Map<String, String> values) onConfirm;

  /// 保管库账号类型（非空则显示"从保管库填充"）
  final String? vaultAccountType;

  const LoginPanel({
    super.key,
    required this.platform,
    required this.desc,
    required this.inputEntries,
    required this.onConfirm,
    this.vaultAccountType,
  });

  @override
  State<StatefulWidget> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<LoginPanel> {
  final Map<String, String> values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.inputEntries) {
      _controllers[item.id] = TextEditingController(text: item.defaultValue);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fillFromVault() async {
    final accountType = widget.vaultAccountType;
    if (accountType == null) return;
    final entry = await showVaultEntryPicker(context, accountType);
    if (entry == null || !mounted) return;
    final idEntry = widget.inputEntries.firstWhere(
      (e) => !e.isPwd,
      orElse: () => widget.inputEntries.first,
    );
    final pwdEntry = widget.inputEntries.firstWhere(
      (e) => e.isPwd,
      orElse: () => widget.inputEntries.last,
    );
    _controllers[idEntry.id]?.text = entry.username;
    _controllers[pwdEntry.id]?.text = entry.password;
    values[idEntry.id] = entry.username;
    values[pwdEntry.id] = entry.password;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      t.title.login_to,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.platform,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: .bold,
                              color: colors.foreground,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        if (widget.vaultAccountType != null)
                          IconButton(
                            icon: const Icon(LucideIcons.keyRound),
                            tooltip: t.vault.fill_from_vault,
                            color: colors.primary,
                            onPressed: _fillFromVault,
                          ),
                      ],
                    ),
                    Text(
                      widget.desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    Column(
                      spacing: 8,
                      children: widget.inputEntries
                          .map<Widget>(
                            (item) => (item.isPwd)
                                ? FTextField.password(
                                    label: Text(item.lable),
                                    hint: item.hint,
                                    description: (item.desc == null)
                                        ? null
                                        : Text(item.desc!),
                                    control: .managed(
                                      controller: _controllers[item.id],
                                      onChange: (value) {
                                        values[item.id] = value.text;
                                      },
                                    ),
                                  )
                                : FTextField(
                                    label: Text(item.lable),
                                    hint: item.hint,
                                    description: (item.desc == null)
                                        ? null
                                        : Text(item.desc!),
                                    control: .managed(
                                      controller: _controllers[item.id],
                                      onChange: (value) {
                                        values[item.id] = value.text;
                                      },
                                    ),
                                  ),
                          )
                          .toList(),
                    ),
                    const FDivider(),
                    const SizedBox(height: 8),
                    FButton(
                      onPress: () {
                        widget.onConfirm(values);
                      },
                      child: Text(t.notice.login),
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
