import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/widget/common_pin_checkin_panel.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/widget/pin_checkin_panel.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/widget/pos_checkin_panel.dart';

Future<String?> openPinInputPanel(
  BuildContext context,
  String title,
  String desc,
  int length, {
  Future<String?> Function()? fetchCheckinCode,
  void Function(String code)? onQuickCheckin,
}) async {
  final completer = Completer<String?>();

  await showFSheet(
    context: context,
    builder: (sheetContext) => PinCheckinPanel(
      title: title,
      desc: desc,
      length: length,
      fetchCheckinCode: fetchCheckinCode,
      onQuickCheckin: (onQuickCheckin == null)
          ? null
          : (code) {
              Navigator.of(sheetContext).pop();
              onQuickCheckin(code);
            },
      onConfirm: (value, crack) {
        Navigator.of(sheetContext).pop();
        if (!completer.isCompleted) {
          if (crack) {
            completer.complete(null);
          } else {
            completer.complete(value);
          }
        }
      },
    ),
    side: .btt,
  );
  return await completer.future;
}

Future<String?> openCommonPinInputPanel(
  BuildContext context,
  String title,
  String desc,
) async {
  final completer = Completer<String?>();

  await showFSheet(
    context: context,
    builder: (sheetContext) => CommonPinCheckinPanel(
      title: title,
      desc: desc,
      onConfirm: (value, crack) {
        Navigator.of(sheetContext).pop();
        if (!completer.isCompleted) {
          if (crack) {
            completer.complete(null);
          } else {
            completer.complete(value);
          }
        }
      },
    ),
    side: .btt,
  );
  return await completer.future;
}

Future<Coordinate> openPosCheckinPanel(
  BuildContext context,
  String title,
  String desc, {
  VoidCallback? onQuickCheckin,
}) async {
  final completer = Completer<Coordinate>();
  await showFSheet(
    context: context,
    builder: (sheetContext) => PosCheckinPanel(
      title: title,
      desc: desc,
      onQuickCheckin: onQuickCheckin,
      onConfirm: (pos) {
        Navigator.of(sheetContext).pop();
        if (!completer.isCompleted) {
          completer.complete(pos);
        }
      },
    ),
    side: .btt,
  );
  return await completer.future;
}
