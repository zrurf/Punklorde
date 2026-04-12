import 'dart:async';

import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:punklorde/module/feature/chaoxing/service/checkin.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:signals/signals_flutter.dart';

final Signal<List<ClassData>> clazzList = signal([]);

Timer? _updateTimer;
bool _updateLock = false;

Future<void> _update() async {
  final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
  if (_updateLock || cred == null) {
    return;
  }
  _updateLock = true;
  final r = await serviceChaoxingCheckin.getCourses(cred);
  if (r != null) {
    clazzList.value = r;
  }
  _updateLock = false;
}

void initStatus() {
  _update();

  _updateTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
    _update();
  });

  effect(() {
    final cred = getPrimaryAuthCredentialByPlatform(platChaoxing.id);
    if (cred != null) {
      _update();
    }
  });
}

void disposeStatus() {
  _updateTimer?.cancel();
}
