import 'package:flutter/material.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/chaoxing/api/client.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/model/checkin.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/pages/checkin_result.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';

class ChaoxingCehckinService {
  final ApiClient _apiClient = ApiClient();

  /// 获得所有课程
  Future<List<ClassData>?> getCourses(AuthCredential cred) async {
    return (await _apiClient.getCourseList(
      await AuthCredentialCache.fromCredential(cred),
    ))?.classes;
  }

  /// 获取所有签到事件
  Future<List<ChaoxingCheckin>> getAllCheckinEvents(
    AuthCredentialCache cred,
    List<ClassData> clazz,
  ) async {
    final List<ChaoxingCheckin> result = [];
    for (final c1 in clazz) {
      for (final c2 in c1.courses) {
        final clazzId = c1.id.toString();
        final courseId = c2.id.toString();
        final r = await _apiClient.getActives(cred, courseId, clazzId);
        if (r == null) continue;
        result.addAll(
          r
              .map(
                (v) => (v.getActiveType != .unknown && v.status == 1)
                    ? ChaoxingCheckin.fromActive(v, clazzId, courseId, c2.name)
                    : null,
              )
              .nonNulls,
        );
      }
    }
    return result;
  }

  /// 检查签到是否成功
  Future<bool> checkinDone(AuthCredentialCache cred, String activeId) {
    return _apiClient.checkinDone(cred, activeId);
  }

  /// 二维码签到
  Future<void> checkinQr(
    BuildContext context,
    List<AuthCredentialCache> credentials,
    String id,
    String enc,
    String enc2,
  ) async {
    final result = await _apiClient.checkinAllQr(credentials, id, enc, enc2);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platChaoxing,
            credentials: credentials.map((v) => v.credential).toList(),
            results: result,
            onRetry: (newCredentials) async {
              final List<AuthCredentialCache> creds = [];
              for (final c in newCredentials) {
                creds.add(await AuthCredentialCache.fromCredential(c));
              }
              if (context.mounted) {
                await checkinQr(context, creds, id, enc, enc2);
              }
            },
          ),
        ),
      );
    }
  }

  /// 签到码签到
  Future<void> checkinCode(
    BuildContext context,
    List<AuthCredentialCache> credentials,
    String id,
    String code,
  ) async {
    final result = await _apiClient.checkinAllCode(credentials, id, code);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platChaoxing,
            credentials: credentials.map((v) => v.credential).toList(),
            results: result,
            onRetry: (newCredentials) async {
              final List<AuthCredentialCache> creds = [];
              for (final c in newCredentials) {
                creds.add(await AuthCredentialCache.fromCredential(c));
              }
              if (context.mounted) {
                await checkinCode(context, credentials, id, code);
              }
            },
          ),
        ),
      );
    }
  }

  /// 位置签到
  Future<void> checkinPos(
    BuildContext context,
    List<AuthCredentialCache> credentials,
    String id,
    Coordinate pos,
  ) async {
    final result = await _apiClient.checkinAllPos(credentials, id, pos);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckinResultPage(
            platform: platChaoxing,
            credentials: credentials.map((v) => v.credential).toList(),
            results: result,
            onRetry: (newCredentials) async {
              final List<AuthCredentialCache> creds = [];
              for (final c in newCredentials) {
                creds.add(await AuthCredentialCache.fromCredential(c));
              }
              if (context.mounted) {
                await checkinPos(context, credentials, id, pos);
              }
            },
          ),
        ),
      );
    }
  }
}

final serviceChaoxingCheckin = ChaoxingCehckinService();
