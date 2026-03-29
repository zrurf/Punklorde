import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:pinput/pinput.dart';
import 'package:punklorde/app/theme/default.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

class PinCheckinPanel extends StatefulWidget {
  final String title;
  final String desc;
  final void Function(String value, bool crack) onConfirm;

  const PinCheckinPanel({
    super.key,
    required this.title,
    required this.desc,
    required this.onConfirm,
  });

  @override
  State<StatefulWidget> createState() => _PinCheckinPanelState();
}

class _PinCheckinPanelState extends State<PinCheckinPanel> {
  String value = "";

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
                        length: 4,
                        defaultPinTheme: switch (themeModeSignal.watch(
                          context,
                        )) {
                          .system =>
                            (MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                                ? pinDarkTheme
                                : pinLightTheme,
                          .light => pinLightTheme,
                          .dark => pinDarkTheme,
                        },
                        onChanged: (v) => value = v,
                      ),
                    ),
                    const FDivider(),
                    const SizedBox(height: 8),
                    FButton(
                      variant: .primary,
                      onPress: () {
                        widget.onConfirm(value, false);
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
