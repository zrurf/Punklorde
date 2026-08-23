import 'package:flutter/material.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/tronclass/model.dart';
import 'package:punklorde/module/feature/tronclass/service.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/config.dart';
import 'package:punklorde/module/model/auth.dart';

/// 学在重邮签到服务（委托共享畅课实现）
class CquptTronCheckinService {
  late final TronclassCheckinService _inner = TronclassCheckinService(
    cquptTronclassConfig,
  );

  Future<List<RollcallModel>> getCheckinEvents(AuthCredential credentials) {
    return _inner.getCheckinEvents(credentials);
  }

  Future<String?> getCheckinNumber(AuthCredential credential, String id) {
    return _inner.getCheckinNumber(credential, id);
  }

  Future<void> checkinQr(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    String data,
  ) {
    return _inner.checkinQr(context, credentials, id, data);
  }

  Future<void> checkinPin(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    String pin,
  ) {
    return _inner.checkinPin(context, credentials, id, pin);
  }

  Future<void> checkinPinCrack(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
  ) {
    return _inner.checkinPinCrack(context, credentials, id);
  }

  Future<void> checkinRadar(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    Coordinate coordinate,
  ) {
    return _inner.checkinRadar(context, credentials, id, coordinate);
  }

  Future<void> checkinRadarAuto(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
  ) {
    return _inner.checkinRadarAuto(context, credentials, id);
  }
}

final serviceCquptTronCheckin = CquptTronCheckinService();
