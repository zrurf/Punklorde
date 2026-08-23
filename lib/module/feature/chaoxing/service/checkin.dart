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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: platChaoxing,
          credentials: credentials.map((v) => v.credential).toList(),
          onCheckin: (creds) async => _apiClient.checkinAllQr(
            await _toCaches(creds),
            id,
            enc,
            enc2,
          ),
        ),
      ),
    );
  }

  /// 签到码签到
  Future<void> checkinCode(
    BuildContext context,
    List<AuthCredentialCache> credentials,
    String id,
    String code,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: platChaoxing,
          credentials: credentials.map((v) => v.credential).toList(),
          onCheckin: (creds) async =>
              _apiClient.checkinAllCode(await _toCaches(creds), id, code),
        ),
      ),
    );
  }

  /// 位置签到
  Future<void> checkinPos(
    BuildContext context,
    List<AuthCredentialCache> credentials,
    String id,
    Coordinate pos,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: platChaoxing,
          credentials: credentials.map((v) => v.credential).toList(),
          onCheckin: (creds) async =>
              _apiClient.checkinAllPos(await _toCaches(creds), id, pos),
        ),
      ),
    );
  }

  /// 将结果页回传的凭证还原为带缓存的凭证
  Future<List<AuthCredentialCache>> _toCaches(
    List<AuthCredential> credentials,
  ) async {
    return [
      for (final c in credentials) await AuthCredentialCache.fromCredential(c),
    ];
  }
}

final serviceChaoxingCheckin = ChaoxingCehckinService();
