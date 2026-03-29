import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/checkin/model.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/widget/pin_checkin_panel.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/widget/pos_checkin_panel.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/model.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/service.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';
import 'package:signals/signals_flutter.dart';

class FeatCquptCheckinView extends StatefulWidget {
  const FeatCquptCheckinView({super.key});

  @override
  State<FeatCquptCheckinView> createState() => _FeatCquptCheckinViewState();
}

class _FeatCquptCheckinViewState extends State<FeatCquptCheckinView> {
  final GlobalKey<_FeatCquptCheckinViewState> widgetKey = GlobalKey();
  final Signal<List<CheckinEvent>?> _checkinEventSignal = signal(null);

  late final AuthCredential? authTronclass;
  Timer? _updateTimer;
  bool _updateLock = false;

  @override
  void initState() {
    super.initState();
    authTronclass = authManager.getPrimaryAuthByPlatform(platCquptTronclass.id);
    _updateLock = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widgetKey.currentContext != null) {
        checkAndUpdateEvents(widgetKey.currentContext!);
      }
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (v) {
        if (widgetKey.currentContext == null) return;
        checkAndUpdateEvents(widgetKey.currentContext!);
      });
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> checkAndUpdateEvents(BuildContext context) async {
    if (_updateLock) return;
    _updateLock = true;

    _checkinEventSignal.value = [
      ...(((authTronclass != null)
              ? await serviceCquptTronCheckin.getCheckinEvents(authTronclass!)
              : <RollcallModel>[])
          .map(
            (v) => CheckinEvent(
              id: v.id,
              platform: platCquptTronclass,
              type: switch (v.type) {
                RollcallType.qr => CheckinType.scan,
                RollcallType.pin => CheckinType.pin,
                RollcallType.radar => CheckinType.position,
              },
              name: v.title ?? t.submodule.cqupt_checkin.check_in,
              desc: v.author ?? v.dept,
              done: v.isDone(),
              onCall: switch (v.type) {
                RollcallType.qr => (Set<AuthCredential> creds) async {
                  await context.push("/p/universal_scan");
                },
                RollcallType.pin => (Set<AuthCredential> creds) async {
                  final r = await _openPinInputPanel(
                    v.title ?? t.submodule.cqupt_checkin.check_in,
                    v.author ?? v.dept ?? '',
                  );
                  if (r == null) {
                    if (context.mounted) {
                      serviceCquptTronCheckin.checkinPinCrack(
                        context,
                        creds.toList(),
                        v.id,
                      );
                    }
                    return;
                  }
                  if (r.isNotEmpty) {
                    if (context.mounted) {
                      serviceCquptTronCheckin.checkinPin(
                        context,
                        creds.toList(),
                        v.id,
                        r,
                      );
                    }
                    return;
                  }
                },
                RollcallType.radar => (Set<AuthCredential> creds) async {
                  final r = await _openPosCheckinPanel(
                    v.title ?? t.submodule.cqupt_checkin.check_in,
                    v.author ?? v.dept ?? '',
                  );
                  if (r) {
                    if (context.mounted) {
                      serviceCquptTronCheckin.checkinRadarDetect(
                        context,
                        creds.toList(),
                        v.id,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      serviceCquptTronCheckin.checkinRadar(
                        context,
                        creds.toList(),
                        v.id,
                      );
                    }
                  }
                },
              },
            ),
          )
          .nonNulls
          .toList()),
    ];
    _updateLock = false;
  }

  Future<String?> _openPinInputPanel(String title, String desc) async {
    final completer = Completer<String?>();

    await showFSheet(
      context: context,
      builder: (sheetContext) => PinCheckinPanel(
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

  Future<bool> _openPosCheckinPanel(String title, String desc) async {
    final completer = Completer<bool>();
    await showFSheet(
      context: context,
      builder: (sheetContext) => PosCheckinPanel(
        title: title,
        desc: desc,
        onConfirm: (crack) {
          Navigator.of(sheetContext).pop();
          if (!completer.isCompleted) {
            completer.complete(crack);
          }
        },
      ),
      side: .btt,
    );
    return await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      key: widgetKey,
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.submodule.cqupt_checkin.title_check_in),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
              suffixes: [
                FHeaderAction(
                  icon: const Icon(LucideIcons.usersRound),
                  onPress: () {
                    context.push('/p/checkin_user');
                  },
                ),
              ],
            ),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: .spaceEvenly,
                children: [
                  FButton(
                    variant: .primary,
                    size: .lg,
                    prefix: const Icon(LucideIcons.scanQrCode, size: 22),
                    child: Text(
                      t.submodule.cqupt_checkin.scan_checkin,
                      style: const TextStyle(fontSize: 18, fontWeight: .bold),
                    ),
                    onPress: () async {
                      await context.push("/p/universal_scan");
                    },
                  ),
                  FButton(
                    variant: .secondary,
                    size: .lg,
                    prefix: const Icon(LucideIcons.history, size: 22),
                    child: Text(
                      t.submodule.cqupt_checkin.checkin_history,
                      style: const TextStyle(fontSize: 18, fontWeight: .bold),
                    ),
                    onPress: () {},
                  ),
                ],
              ),
            ),
            const Padding(
              padding: .symmetric(horizontal: 16),
              child: FDivider(),
            ),

            (_checkinEventSignal.watch(context) != null)
                ? Expanded(
                    child: ListView.builder(
                      padding: const .symmetric(horizontal: 16, vertical: 8),
                      itemCount: max(
                        _checkinEventSignal.watch(context)!.length,
                        1,
                      ),
                      itemBuilder: (context, index) {
                        if (_checkinEventSignal.value!.isEmpty) {
                          return Center(
                            child: Column(
                              spacing: 8,
                              mainAxisSize: .min,
                              mainAxisAlignment: .center,
                              children: [
                                Icon(
                                  LucideIcons.clipboardCheck,
                                  color: colors.primary,
                                  size: 32,
                                ),
                                Text(
                                  t.submodule.cqupt_checkin.no_ongoing_checkin,
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                    fontSize: 18,
                                  ),
                                  textAlign: .center,
                                ),
                              ],
                            ),
                          );
                        }
                        final event = _checkinEventSignal.watch(
                          context,
                        )![index];
                        return Padding(
                          padding: const .symmetric(vertical: 4),
                          child: FTile(
                            title: Column(
                              crossAxisAlignment: .start,
                              spacing: 4,
                              children: [
                                Row(
                                  spacing: 4,
                                  children: [
                                    Icon(
                                      LucideIcons.layers2,
                                      size: 16,
                                      color: colors.primary,
                                    ),
                                    Text(
                                      event.platform.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),

                                Text(
                                  event.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: .bold,
                                  ),
                                ),
                                Text(
                                  event.desc ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: .only(top: 8),
                              child: FBadge(
                                child: Text(switch (event.type) {
                                  CheckinType.scan =>
                                    t.submodule.cqupt_checkin.qrcode_checkin,
                                  CheckinType.position =>
                                    t.submodule.cqupt_checkin.pos_checkin,
                                  CheckinType.pin =>
                                    t.submodule.cqupt_checkin.pin_checkin,
                                  CheckinType.gesture =>
                                    t.submodule.cqupt_checkin.gesture_checkin,
                                  CheckinType.other =>
                                    t
                                        .submodule
                                        .cqupt_checkin
                                        .unsupported_checkin,
                                }, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            details: (event.done)
                                ? FBadge(
                                    variant: .primary,
                                    child: Text(
                                      t.submodule.cqupt_checkin.already_checkin,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )
                                : null,
                            prefix: Icon(switch (event.type) {
                              CheckinType.scan => LucideIcons.qrCode,
                              CheckinType.position => LucideIcons.mapPin,
                              CheckinType.pin => LucideIcons.textCursorInput,
                              CheckinType.gesture => LucideIcons.lineSquiggle,
                              CheckinType.other => LucideIcons.circleDashed,
                            }, size: 36),
                            onPress: (!event.done)
                                ? () async {
                                    await event.onCall(
                                      checkinAuthSignal.value
                                          .where(
                                            (v) => v.type == event.platform.id,
                                          )
                                          .toSet(),
                                    );
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  )
                : Expanded(
                    child: Center(
                      child: FCircularProgress(
                        size: .xl,
                        style: .delta(iconStyle: .delta(color: colors.primary)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
