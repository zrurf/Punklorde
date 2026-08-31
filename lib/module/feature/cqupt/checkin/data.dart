import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/experiment.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/data.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/service/checkin.dart';
import 'package:punklorde/module/feature/cqupt/checkin/model.dart';
import 'package:punklorde/module/feature/cqupt/checkin/utils/view.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/config.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/model.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/service.dart';
import 'package:punklorde/module/feature/tronclass/view/course_qr_checkin_page.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';
import 'package:signals/signals_flutter.dart';

final Computed<List<CheckinEvent>> checkinEventSignal = computed(() {
  return [...tronEventSignal.value, ...chaoxingEventSignal.value];
});

final Signal<List<CheckinEvent>> tronEventSignal = signal([]);
final Signal<List<CheckinEvent>> chaoxingEventSignal = signal([]);

final _format = DateFormat("MM-dd HH:mm");

bool _tronFetchLock = false;
bool _chaoxingFetchLock = false;

/// 获取签到事件
Future<void> fetchEvent(BuildContext context) async {
  if (_tronFetchLock || _chaoxingFetchLock) return;
  await batch(() async {
    if (context.mounted) await fetchTronEvent(context);
    if (context.mounted) await fetchChaoxingEvent(context);
  });
}

/// 获取学在重邮签到事件
Future<void> fetchTronEvent(BuildContext context) async {
  if (_tronFetchLock) return;
  _tronFetchLock = true;
  tronEventSignal.value = await fetchFromCquptTron(context);
  _tronFetchLock = false;
}

/// 获取学习通签到事件
Future<void> fetchChaoxingEvent(BuildContext context) async {
  if (_chaoxingFetchLock) return;
  _chaoxingFetchLock = true;
  chaoxingEventSignal.value = await fetchFromChaoxing(context);
  _chaoxingFetchLock = false;
}

/// 从学在重邮获取签到事件
Future<List<CheckinEvent>> fetchFromCquptTron(BuildContext context) async {
  final auth = authManager.getPrimaryAuthByPlatform(platCquptTronclass.id);
  return ((auth != null)
          ? await serviceCquptTronCheckin.getCheckinEvents(auth)
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
          desc: "${v.author ?? ''}-${v.dept ?? ''}",
          done: v.isDone(),
          onCall: switch (v.type) {
            RollcallType.qr => (Set<AuthCredential> creds) async {
              if (isExperimentEnabled(experimentCrossCourseCheckin.id)) {
                await showCourseCheckinSheet(
                  context,
                  config: cquptTronclassConfig,
                  rollcallId: v.id,
                  courseTitle: v.title ?? t.submodule.cqupt_checkin.check_in,
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
                4,
                fetchCheckinCode: (auth == null)
                    ? null
                    : () =>
                          serviceCquptTronCheckin.getCheckinNumber(auth, v.id),
                onQuickCheckin: (auth == null)
                    ? null
                    : (code) {
                        if (context.mounted) {
                          serviceCquptTronCheckin.checkinPin(
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
                serviceCquptTronCheckin.checkinPinCrack(
                  context,
                  credList,
                  v.id,
                );
                return;
              }
              if (r.isNotEmpty) {
                serviceCquptTronCheckin.checkinPin(context, credList, v.id, r);
                return;
              }
            },
            RollcallType.radar => (Set<AuthCredential> creds) async {
              final r = await openPosCheckinPanel(
                context,
                v.title ?? t.submodule.cqupt_checkin.check_in,
                "${v.author ?? ''}-${v.dept ?? ''}",
                onQuickCheckin: () {
                  serviceCquptTronCheckin.checkinRadarAuto(
                    context,
                    creds.toList(),
                    v.id,
                  );
                },
              );
              if (!context.mounted) return;
              serviceCquptTronCheckin.checkinRadar(
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
}

/// 从学习通获取签到事件
Future<List<CheckinEvent>> fetchFromChaoxing(BuildContext context) async {
  final auth = authManager.getPrimaryAuthByPlatform(platChaoxing.id);

  if (auth == null) {
    return [];
  }

  final authCache = await AuthCredentialCache.fromCredential(auth);

  final clazz = clazzList.value;

  final events = await serviceChaoxingCheckin.getAllCheckinEvents(
    authCache,
    clazz,
  );

  final List<CheckinEvent> result = [];

  for (final ev in events) {
    final done = await serviceChaoxingCheckin.checkinDone(authCache, ev.signId);
    result.add(
      CheckinEvent(
        id: ev.signId,
        platform: platChaoxing,
        type: switch (ev.type) {
          .qr => CheckinType.scan,
          .code => CheckinType.pin,
          .location => CheckinType.position,
          .gesture => CheckinType.gesture,
          .normal => CheckinType.other,
        },
        name: ev.title,
        desc:
            "${ev.desc}\n"
            "${_format.format(ev.startTime)} - "
            "${(ev.endTime != null) ? _format.format(ev.endTime!) : "教师手动截止"}",
        done: done,
        onCall: switch (ev.type) {
          .qr => (Set<AuthCredential> creds) async {
            await context.push("/p/universal_scan");
          },
          .code => (Set<AuthCredential> creds) async {
            final List<AuthCredentialCache> credsCache = [];

            for (final cred in creds) {
              credsCache.add(await AuthCredentialCache.fromCredential(cred));
            }
            if (context.mounted) {
              final r = await openCommonPinInputPanel(
                context,
                ev.title,
                ev.desc,
              );
              if (r != null && context.mounted) {
                serviceChaoxingCheckin.checkinCode(
                  context,
                  credsCache,
                  ev.signId,
                  r,
                );
                return;
              }
            }
          },
          .gesture => (Set<AuthCredential> creds) async {},
          .location => (Set<AuthCredential> creds) async {
            final List<AuthCredentialCache> credsCache = [];

            for (final cred in creds) {
              credsCache.add(await AuthCredentialCache.fromCredential(cred));
            }

            if (context.mounted) {
              final r = await openPosCheckinPanel(context, ev.title, ev.desc);
              if (context.mounted) {
                serviceChaoxingCheckin.checkinPos(
                  context,
                  credsCache,
                  ev.signId,
                  r,
                );
              }
            }
          },
          .normal => (Set<AuthCredential> creds) async {},
        },
      ),
    );
  }

  return result;
}
