import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:punklorde/module/platform/chaoxing/model.dart';
import 'package:signals/signals_flutter.dart';

/// 学习通登录页 UI
class ChaoxingLoginPage extends StatefulWidget {
  final Future<void> Function(String phone, bool isIos) sendVerifyCode;
  final void Function(ChaoxingLoginConfig) onConfirm;
  const ChaoxingLoginPage({
    super.key,
    required this.sendVerifyCode,
    required this.onConfirm,
  });

  @override
  State<ChaoxingLoginPage> createState() => _ChaoxingLoginPageState();
}

class _ChaoxingLoginPageState extends State<ChaoxingLoginPage> {
  ChaoxingLoginMethod? _method;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          spacing: 16,
          children: [
            FHeader.nested(
              prefixes: [
                FHeaderAction.x(onPress: () => Navigator.of(context).pop()),
              ],
              title: Text("${t.title.login_to} ${platChaoxing.name}"),
            ),
            Expanded(
              child: Padding(
                padding: const .symmetric(horizontal: 32, vertical: 16),
                child: _method == null
                    ? _buildMethodSelector(colors)
                    : _buildCurrentPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择登录方式
  Widget _buildMethodSelector(FColors colors) {
    return Column(
      children: [
        Text(
          t.title.select_login_method,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 24),
        _MethodCard(
          icon: LucideIcons.keyRound,
          title: t.action.pwd_login,
          onTap: () => _setMethod(.pwd),
        ),
        const SizedBox(height: 16),
        _MethodCard(
          icon: LucideIcons.rectangleEllipsis,
          title: t.action.sms_login,
          onTap: () => _setMethod(.sms),
        ),
      ],
    );
  }

  /// 根据 _method 跳转到对应页面
  Widget _buildCurrentPage() {
    switch (_method) {
      case ChaoxingLoginMethod.pwd:
        return SingleChildScrollView(
          child: _PasswordForm(
            onBack: _resetMethod,
            onConfirm: widget.onConfirm,
          ),
        );
      case ChaoxingLoginMethod.sms:
        return SingleChildScrollView(
          child: _SmsCodeForm(
            onBack: _resetMethod,
            onConfirm: widget.onConfirm,
            sendVerifyCode: widget.sendVerifyCode,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _setMethod(ChaoxingLoginMethod m) {
    setState(() {
      _method = m;
    });
  }

  void _resetMethod() {
    setState(() {
      _method = null;
    });
  }
}

/// 方法选择卡片
class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTile(
      prefix: Icon(icon, size: 28, color: colors.primary),
      suffix: const Icon(LucideIcons.chevronRight, size: 20),
      onPress: onTap,
      title: Padding(
        padding: const .all(8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}

/// 账号密码表单
class _PasswordForm extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(ChaoxingLoginConfig) onConfirm;
  const _PasswordForm({required this.onBack, required this.onConfirm});

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final Signal<String> _phoneSignal = signal("");
  final Signal<String> _passwordSignal = signal("");
  final Signal<bool> _useIosUa = signal(false);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            t.action.pwd_login,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          FTextFormField(
            control: .managed(
              onChange: (value) => _phoneSignal.value = value.text,
            ),
            label: Text(t.title.phone_num),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.notice.phone_num_empty_hint
                : null,
          ),
          const SizedBox(height: 12),
          FTextFormField.password(
            control: .managed(
              onChange: (value) => _passwordSignal.value = value.text,
            ),
            label: Text(t.common.password),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.notice.pwd_empty_hint
                : null,
          ),
          const SizedBox(height: 12),
          FCheckbox(
            label: Text(t.title.use_ios_ua),
            value: _useIosUa.watch(context),
            onChange: (value) => _useIosUa.value = value,
          ),
          const FDivider(),
          FButton(
            variant: .primary,
            onPress: _onSubmit,
            child: Text(t.notice.login),
          ),
          const SizedBox(height: 12),
          FButton(
            variant: .secondary,
            onPress: () {
              widget.onBack();
            },
            prefix: Icon(LucideIcons.arrowLeft),
            child: Text(t.action.back),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onConfirm(
      ChaoxingLoginConfig(
        method: .pwd,
        phone: _phoneSignal.value.trim(),
        value: _passwordSignal.value.trim(),
        useIosUa: _useIosUa.value,
      ),
    );
    Navigator.of(context).pop();
  }
}

/// 短信验证码表单
class _SmsCodeForm extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(ChaoxingLoginConfig) onConfirm;
  final Future<void> Function(String phone, bool isIos) sendVerifyCode;
  const _SmsCodeForm({
    required this.onBack,
    required this.onConfirm,
    required this.sendVerifyCode,
  });

  @override
  State<_SmsCodeForm> createState() => _SmsCodeFormState();
}

class _SmsCodeFormState extends State<_SmsCodeForm> {
  final _formKey = GlobalKey<FormState>();
  final Signal<String> _phoneSignal = signal("");
  final Signal<String> _codeSignal = signal("");
  final Signal<bool> _useIosUa = signal(false);
  final Signal<int> _verCodeSendCdSignal = signal(0);

  Timer? _verCodeSendTimer;
  bool _sendLock = false;

  @override
  void dispose() {
    _verCodeSendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            t.action.sms_login,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          FTextFormField(
            control: .managed(
              onChange: (value) => _phoneSignal.value = value.text,
            ),
            label: Text(t.title.phone_num),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.notice.phone_num_empty_hint
                : null,
          ),
          const SizedBox(height: 12),
          FTextFormField(
            control: .managed(
              onChange: (value) => _codeSignal.value = value.text,
            ),
            label: Text(t.title.verification_code),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.notice.ver_code_empty_hint
                : null,
          ),
          const SizedBox(height: 16),
          FButton(
            onPress: (_verCodeSendCdSignal.watch(context) <= 0)
                ? () {
                    _onSendVerCode();
                  }
                : null,
            child: (_verCodeSendCdSignal.watch(context) <= 0)
                ? Text(t.action.send_sms_code)
                : Text("${_verCodeSendCdSignal.watch(context).toString()}s"),
          ),
          const SizedBox(height: 16),
          FCheckbox(
            label: Text(t.title.use_ios_ua),
            value: _useIosUa.watch(context),
            onChange: (value) => _useIosUa.value = value,
          ),
          const FDivider(),
          FButton(
            variant: .primary,
            onPress: _onSubmit,
            child: Text(t.notice.login),
          ),
          const SizedBox(height: 12),
          FButton(
            variant: .secondary,
            onPress: () {
              widget.onBack();
              Navigator.of(context).pop();
            },
            prefix: Icon(LucideIcons.arrowLeft),
            child: Text(t.action.back),
          ),
        ],
      ),
    );
  }

  Future<void> _onSendVerCode() async {
    if (_sendLock || _verCodeSendCdSignal.value > 0) return;
    _sendLock = true;
    _verCodeSendTimer?.cancel();
    final phone = _phoneSignal.value.trim();
    await widget.sendVerifyCode(phone, _useIosUa.value);
    _verCodeSendCdSignal.value = 60;
    _verCodeSendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _verCodeSendCdSignal.value--;
      if (_verCodeSendCdSignal.value <= 0) {
        timer.cancel();
        _verCodeSendTimer = null;
      }
    });
    _sendLock = false;
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onConfirm(
      ChaoxingLoginConfig(
        method: .sms,
        phone: _phoneSignal.value.trim(),
        value: _codeSignal.value.trim(),
        useIosUa: _useIosUa.value,
      ),
    );
    Navigator.of(context).pop();
  }
}
