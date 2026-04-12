import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/i18n/strings.g.dart';

class PosCheckinPanel extends StatefulWidget {
  final String title;
  final String desc;
  final void Function(Coordinate coord) onConfirm;

  const PosCheckinPanel({
    super.key,
    required this.title,
    required this.desc,
    required this.onConfirm,
  });

  @override
  State<StatefulWidget> createState() => _PosCheckinPanelState();
}

class _PosCheckinPanelState extends State<PosCheckinPanel> {
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
                    const SizedBox(height: 8),
                    FButton(
                      variant: .secondary,
                      onPress: () {},
                      prefix: const Icon(LucideIcons.mapPinSearch),
                      child: Text(
                        t.submodule.cqupt_checkin.checkin_use_auto_loc,
                      ),
                    ),
                    FButton(
                      variant: .secondary,
                      onPress: () {},
                      prefix: const Icon(LucideIcons.mousePointerClick),
                      child: Text(t.action.manual_select_point),
                    ),
                    FButton(
                      variant: .primary,
                      onPress: () {
                        widget.onConfirm(
                          Coordinate(lat: rawLat.value, lng: rawLng.value),
                        );
                      },
                      prefix: const Icon(LucideIcons.locateFixed),
                      child: Text(
                        t.submodule.cqupt_checkin.checkin_use_current_loc,
                      ),
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
