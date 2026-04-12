import 'package:flutter/material.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/pages/checkin_result.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/api/client.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/model.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';

class CquptTronCheckinService {
  final ApiClient _apiClient = ApiClient();

  /// 获取签到事件
  Future<List<RollcallModel>> getCheckinEvents(
    AuthCredential credentials,
  ) async {
    return await _apiClient.getCheckinEvents(credentials) ?? [];
  }

  /// 二维码签到
  Future<void> checkinQr(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    String data,
  ) async {
    final result = await _apiClient.checkinAllQr(credentials, id, data);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platCquptTronclass,
            credentials: credentials,
            results: result,
            onRetry: (newCredentials) async {
              await checkinQr(context, newCredentials, id, data);
            },
          ),
        ),
      );
    }
  }

  /// PIN签到
  Future<void> checkinPin(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    String pin,
  ) async {
    final result = await _apiClient.checkinAllPin(credentials, id, pin);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platCquptTronclass,
            credentials: credentials,
            results: result,
            onRetry: (newCredentials) async {
              await checkinPin(context, newCredentials, id, pin);
            },
          ),
        ),
      );
    }
  }

  /// 暴力PIN签到
  Future<void> checkinPinCrack(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
  ) async {
    final result = await _apiClient.checkinAllPinCrack(credentials, id);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platCquptTronclass,
            credentials: credentials,
            results: result,
            onRetry: (newCredentials) async {
              await checkinPinCrack(context, newCredentials, id);
            },
          ),
        ),
      );
    }
  }

  /// 雷达签到
  Future<void> checkinRadar(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    Coordinate coordinate,
  ) async {
    final result = await _apiClient.checkinAllRadar(
      credentials,
      id,
      coordinate,
      rawSpeed.value,
      50,
    );
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platCquptTronclass,
            credentials: credentials,
            results: result,
            onRetry: (newCredentials) async {
              await checkinRadar(context, newCredentials, id, coordinate);
            },
          ),
        ),
      );
    }
  }
}

final serviceCquptTronCheckin = CquptTronCheckinService();
