import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/experiment.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/tronclass/model.dart';
import 'package:punklorde/module/feature/cqupt/checkin/model.dart';
import 'package:punklorde/module/feature/cqupt/checkin/utils/view.dart';
import 'package:punklorde/module/feature/cuc/tronclass/config.dart';
import 'package:punklorde/module/feature/tronclass/view/course_qr_checkin_page.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cuc/tronclass.dart';
import 'package:signals/signals_flutter.dart';

final Signal<List<CheckinEvent>> cucCheckinEventSignal = signal([]);

/// 获取中传畅课签到事件
Future<void> fetchCucCheckinEvent(BuildContext context) async {
  final auth = authManager.getPrimaryAuthByPlatform(platCucTronclass.id);
  final events =
      ((auth != null)
              ? await serviceCucTronclassCheckin.getCheckinEvents(auth)
              : <RollcallModel>[])
          .map(
            (v) => CheckinEvent(
              id: v.id,
              platform: platCucTronclass,
              type: switch (v.type) {
                RollcallType.qr => CheckinType.scan,
                RollcallType.pin => CheckinType.pin,
                RollcallType.radar => CheckinType.position,
              },
              name: v.title ?? t.submodule.cqupt_checkin.check_in,
              desc: "${v.author ?? ''}-${v.dept ?? ''}",
              done: v.isDone(),
              onCall: switch (v.type) {
                RollcallType.qr => (Set<AuthCredential> creds) async {
                  if (isExperimentEnabled(experimentCrossCourseCheckin.id)) {
                    await showCourseCheckinSheet(
                      context,
                      config: cucTronclassConfig,
                      rollcallId: v.id,
                      courseTitle:
                          v.title ?? t.submodule.cqupt_checkin.check_in,
                    );
                    return;
                  }
                  await context.push("/p/universal_scan");
                },
                RollcallType.pin => (Set<AuthCredential> creds) async {
                  final credList = creds.toList();
                  final auth = (credList.isNotEmpty) ? credList.first : null;
                  final r = await openPinInputPanel(
                    context,
                    v.title ?? t.submodule.cqupt_checkin.check_in,
                    "${v.author ?? ''}-${v.dept ?? ''}",
                    cucTronclassConfig.pinLength,
                    fetchCheckinCode: (auth == null)
                        ? null
                        : () => serviceCucTronclassCheckin.getCheckinNumber(
                            auth,
                            v.id,
                          ),
                    onQuickCheckin: (auth == null)
                        ? null
                        : (code) {
                            if (context.mounted) {
                              serviceCucTronclassCheckin.checkinPin(
                                context,
                                credList,
                                v.id,
                                code,
                              );
                            }
                          },
                  );
                  if (!context.mounted) return;
                  if (r == null) {
                    serviceCucTronclassCheckin.checkinPinCrack(
                      context,
                      credList,
                      v.id,
                    );
                    return;
                  }
                  if (r.isNotEmpty) {
                    serviceCucTronclassCheckin.checkinPin(
                      context,
                      credList,
                      v.id,
                      r,
                    );
                    return;
                  }
                },
                RollcallType.radar => (Set<AuthCredential> creds) async {
                  final r = await openPosCheckinPanel(
                    context,
                    v.title ?? t.submodule.cqupt_checkin.check_in,
                    "${v.author ?? ''}-${v.dept ?? ''}",
                    onQuickCheckin: () {
                      serviceCucTronclassCheckin.checkinRadarAuto(
                        context,
                        creds.toList(),
                        v.id,
                      );
                    },
                  );
                  if (!context.mounted) return;
                  serviceCucTronclassCheckin.checkinRadar(
                    context,
                    creds.toList(),
                    v.id,
                    r,
                  );
                },
              },
            ),
          )
          .toList();
  cucCheckinEventSignal.value = events;
}
