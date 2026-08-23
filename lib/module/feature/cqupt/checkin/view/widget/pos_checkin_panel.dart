import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/app/view/page/map_picker.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/service/lbs/location.dart';

class PosCheckinPanel extends StatefulWidget {
  final String title;
  final String desc;
  final void Function(Coordinate coord) onConfirm;

  /// 一键签到回调（非空则显示"一键签到"按钮）
  final VoidCallback? onQuickCheckin;

  const PosCheckinPanel({
    super.key,
    required this.title,
    required this.desc,
    required this.onConfirm,
    this.onQuickCheckin,
  });

  @override
  State<StatefulWidget> createState() => _PosCheckinPanelState();
}

class _PosCheckinPanelState extends State<PosCheckinPanel> {
  @override
  void initState() {
    startLocationService(LocationServiceOptions());
    super.initState();
  }

  @override
  void dispose() {
    stopLocationService();
    super.dispose();
  }

  Future<void> _manualSelectPoint() async {
    final Coordinate? result = await Navigator.of(context, rootNavigator: true)
        .push<Coordinate>(
          MaterialPageRoute(builder: (context) => const MapPickerPage()),
        );
    if (result != null && mounted) {
      widget.onConfirm(result);
    }
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
                      t.submodule.cqupt_checkin.pos_checkin,
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
                    if (widget.onQuickCheckin != null)
                      FButton(
                        variant: .primary,
                        onPress: () {
                          Navigator.of(context).pop();
                          widget.onQuickCheckin!();
                        },
                        prefix: const Icon(Icons.bolt),
                        child: Text(t.submodule.cqupt_checkin.checkin_quick),
                      ),
                    FButton(
                      variant: .secondary,
                      onPress: _manualSelectPoint,
                      prefix: const Icon(LucideIcons.mousePointerClick),
                      child: Text(t.action.manual_select_point),
                    ),
                    FButton(
                      variant: .outline,
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
