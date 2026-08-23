import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:pinput/pinput.dart';
import 'package:punklorde/app/theme/default.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

class PinCheckinPanel extends SignalStatefulWidget {
  final String title;
  final String desc;
  final int length;
  final void Function(String value, bool crack) onConfirm;

  /// 获取签到码（填充/一键签到用，null 时不显示相关按钮）
  final Future<String?> Function()? fetchCheckinCode;

  /// 一键签到（获取签到码后直接提交）
  final void Function(String code)? onQuickCheckin;

  const PinCheckinPanel({
    super.key,
    required this.title,
    required this.desc,
    required this.length,
    required this.onConfirm,
    this.fetchCheckinCode,
    this.onQuickCheckin,
  });

  @override
  State<StatefulWidget> createState() => _PinCheckinPanelState();
}

class _PinCheckinPanelState extends State<PinCheckinPanel> {
  final TextEditingController _controller = TextEditingController();

  /// 是否正在请求签到码
  bool _filling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _fetch() async {
    final result = await widget.fetchCheckinCode?.call();
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _fill() async {
    if (_filling || widget.fetchCheckinCode == null) return;
    setState(() => _filling = true);
    final code = await _fetch();
    if (!mounted) return;
    setState(() {
      _filling = false;
      if (code != null) _controller.text = code;
    });
  }

  Future<void> _quick() async {
    final onQuick = widget.onQuickCheckin;
    if (onQuick == null || widget.fetchCheckinCode == null) return;
    final code = await _fetch();
    if (code == null) return;
    onQuick(code);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final hasFetch = widget.fetchCheckinCode != null;
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
                      t.submodule.cqupt_checkin.pin_checkin,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: .bold,
                        color: colors.foreground,
                      ),
                      maxLines: 2,
                    ),
                    Text(
                      widget.desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    Center(
                      child: Pinput(
                        controller: _controller,
                        length: widget.length,
                        defaultPinTheme: switch (themeModeSignal.value) {
                          .system =>
                            (MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                                ? pinDarkTheme
                                : pinLightTheme,
                          .light => pinLightTheme,
                          .dark => pinDarkTheme,
                        },
                        onChanged: (v) {},
                      ),
                    ),
                    const FDivider(),
                    const SizedBox(height: 8),
                    if (widget.onQuickCheckin != null && hasFetch)
                      FButton(
                        variant: .primary,
                        prefix: const Icon(Icons.bolt),
                        onPress: _quick,
                        child: Text(t.submodule.cqupt_checkin.checkin_quick),
                      ),
                    if (hasFetch) ...[
                      FButton(
                        variant: .secondary,
                        prefix: const Icon(Icons.download),
                        suffix: _filling
                            ? const FCircularProgress(size: .xs)
                            : null,
                        onPress: _filling ? null : _fill,
                        child: Text(
                          t.submodule.cqupt_checkin.checkin_fill_code,
                        ),
                      ),
                    ],
                    FButton(
                      variant: .outline,
                      onPress: () {
                        widget.onConfirm(_controller.text, false);
                      },
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
