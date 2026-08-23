import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/module/feature/tronclass/api/client.dart';
import 'package:punklorde/module/feature/tronclass/config.dart';
import 'package:punklorde/module/feature/tronclass/model.dart';
import 'package:punklorde/module/feature/cqupt/checkin/view/pages/checkin_result.dart';
import 'package:punklorde/module/model/auth.dart';

class TronclassCheckinService {
  final TronclassConfig config;
  late final TronclassApiClient _apiClient = TronclassApiClient(config);

  /// 一键签到抖动最大半径（米，阶梯教室大小）
  static const double _jitterMaxDistance = 20;

  TronclassCheckinService(this.config);

  /// 获取签到事件
  Future<List<RollcallModel>> getCheckinEvents(
    AuthCredential credentials,
  ) async {
    return await _apiClient.getCheckinEvents(credentials) ?? [];
  }

  /// 获取数字签到码
  Future<String?> getCheckinNumber(AuthCredential credential, String id) async {
    return await _apiClient.queryCheckinNumber(credential, id);
  }

  /// 二维码签到
  Future<void> checkinQr(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    String data,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: config.platform,
          credentials: credentials,
          onCheckin: (creds) => _apiClient.checkinAllQr(creds, id, data),
        ),
      ),
    );
  }

  /// PIN签到
  Future<void> checkinPin(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    String pin,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: config.platform,
          credentials: credentials,
          onCheckin: (creds) => _apiClient.checkinAllPin(creds, id, pin),
        ),
      ),
    );
  }

  /// 暴力PIN签到
  Future<void> checkinPinCrack(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: config.platform,
          credentials: credentials,
          onCheckin: (creds) => _apiClient.checkinAllPinCrack(creds, id),
        ),
      ),
    );
  }

  /// 雷达签到
  Future<void> checkinRadar(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
    Coordinate coordinate,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckinResultPage(
          platform: config.platform,
          credentials: credentials,
          onCheckin: (creds) =>
              _apiClient.checkinAllRadar(creds, id, coordinate, rawSpeed.value, 50),
        ),
      ),
    );
  }

  /// 一键雷达签到（探测签到中心，加阶梯教室级抖动后签到）
  Future<void> checkinRadarAuto(
    BuildContext context,
    List<AuthCredential> credentials,
    String id,
  ) async {
    if (credentials.isEmpty) return;
    final aux = _auxiliaryPoints();
    if (aux == null || !context.mounted) return;
    if (context.mounted) context.loaderOverlay.show();
    final candidates = await _apiClient.detectCheckinCoord(
      credentials.first,
      id,
      aux.$1,
      aux.$2,
    );
    final center = _pickCenter(candidates);
    if (context.mounted) context.loaderOverlay.hide();
    if (center == null || !context.mounted) return;

    await checkinRadar(context, credentials, id, _jitter(center));
  }

  /// 探测用辅助点：优先使用配置的固定点，否则以当前位置生成两个偏移点
  (Coordinate, Coordinate)? _auxiliaryPoints() {
    final fixedA = config.radarAuxiliaryA;
    final fixedB = config.radarAuxiliaryB;
    if (fixedA != null && fixedB != null) return (fixedA, fixedB);
    final currentLat = rawLat.value;
    final currentLng = rawLng.value;
    if (currentLat == 0 && currentLng == 0) return null;
    final center = Coordinate(lat: currentLat, lng: currentLng);
    return (_offset(center, 100, 0), _offset(center, 0, 100));
  }

  /// 从候选交点中选出最接近当前位置的点
  Coordinate? _pickCenter(List<Coordinate> candidates) {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;
    final currentLat = rawLat.value;
    final currentLng = rawLng.value;
    if (currentLat == 0 && currentLng == 0) return candidates.first;
    var best = candidates.first;
    var bestDist = double.infinity;
    for (final c in candidates) {
      final dLat = (c.lat - currentLat) * 111320;
      final dLng =
          (c.lng - currentLng) * 111320 * cos(currentLat * pi / 180);
      final dist = dLat * dLat + dLng * dLng;
      if (dist < bestDist) {
        bestDist = dist;
        best = c;
      }
    }
    return best;
  }

  /// 在签到中心附近生成阶梯教室级随机偏移
  Coordinate _jitter(Coordinate center) {
    final angle = Random().nextDouble() * 2 * pi;
    final dist = _jitterMaxDistance * (0.25 + 0.75 * Random().nextDouble());
    return _offset(center, dist * cos(angle), dist * sin(angle));
  }

  /// 以米为单位生成方位偏移
  Coordinate _offset(Coordinate origin, double east, double north) {
    final dLat = north / 111320;
    final dLng = east / (111320 * cos(origin.lat * pi / 180));
    return Coordinate(lat: origin.lat + dLat, lng: origin.lng + dLng);
  }
}