import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/checkin/data.dart';
import 'package:punklorde/module/feature/cqupt/checkin/model.dart';
import 'package:signals/signals_flutter.dart';

class FeatCquptCheckinView extends StatefulWidget {
  const FeatCquptCheckinView({super.key});

  @override
  State<FeatCquptCheckinView> createState() => _FeatCquptCheckinViewState();
}

class _FeatCquptCheckinViewState extends State<FeatCquptCheckinView> {
  final GlobalKey<_FeatCquptCheckinViewState> widgetKey = GlobalKey();
  final Signal<bool> _initialized = signal(false);
  Timer? _tronUpdateTimer;
  Timer? _chaoxingUpdateTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = widgetKey.currentContext;
      if (context != null) {
        fetchEvent(context).then((_) {
          _initialized.value = true;
        });
      }
      _tronUpdateTimer = Timer.periodic(const Duration(seconds: 2), (v) {
        if (context == null) return;
        fetchTronEvent(context);
      });
      _chaoxingUpdateTimer = Timer.periodic(const Duration(seconds: 20), (v) {
        if (context == null) return;
        fetchChaoxingEvent(context);
      });
    });
  }

  @override
  void dispose() {
    _tronUpdateTimer?.cancel();
    _chaoxingUpdateTimer?.cancel();
    super.dispose();
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

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await fetchEvent(context);
                },
                color: colors.primary,
                child: (_initialized.watch(context))
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: max(
                          checkinEventSignal.watch(context).length,
                          1,
                        ),
                        itemBuilder: (context, index) {
                          if (checkinEventSignal.value.isEmpty) {
                            return Center(
                              child: Column(
                                spacing: 8,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.clipboardCheck,
                                    color: colors.primary,
                                    size: 32,
                                  ),
                                  Text(
                                    t
                                        .submodule
                                        .cqupt_checkin
                                        .no_ongoing_checkin,
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          final event = checkinEventSignal.watch(
                            context,
                          )[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                                      fontSize: 18,
                                      fontWeight: .bold,
                                    ),
                                    softWrap: true,
                                  ),
                                  Text(
                                    event.desc ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.mutedForeground,
                                    ),
                                    softWrap: true,
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
                                  }, style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              details: (event.done)
                                  ? FBadge(
                                      variant: .primary,
                                      child: Text(
                                        t
                                            .submodule
                                            .cqupt_checkin
                                            .already_checkin,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    )
                                  : null,
                              prefix: Icon(switch (event.type) {
                                CheckinType.scan => LucideIcons.qrCode,
                                CheckinType.position => LucideIcons.mapPin,
                                CheckinType.pin => LucideIcons.textCursorInput,
                                CheckinType.gesture => LucideIcons.lineSquiggle,
                                CheckinType.other => LucideIcons.circleDashed,
                              }, size: 32),
                              onPress: () async {
                                await event.onCall(
                                  checkinAuthSignal.value
                                      .map((v) {
                                        final cred = authCredentials.value[v];
                                        return (cred?.type == event.platform.id)
                                            ? cred
                                            : null;
                                      })
                                      .nonNulls
                                      .toSet(),
                                );
                              },
                            ),
                          );
                        },
                      )
                    : ListView(
                        children: [
                          Center(
                            child: FCircularProgress(
                              size: .xl,
                              style: .delta(
                                iconStyle: .delta(color: colors.primary),
                              ),
                            ),
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
}
