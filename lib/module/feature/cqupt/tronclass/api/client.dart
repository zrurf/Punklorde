import 'dart:async';

import 'package:dio/dio.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/api/endpoint.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/model.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/utils/brute_force.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/utils/math.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/utils/ua.dart';
import 'package:punklorde/utils/uuid.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static final String _ua = UAUtil.getUA(.wxwork);

  Map<String, dynamic> _getHeader(String sessionId) => {
    "User-Agent": _ua,
    "X-SESSION-ID": sessionId,
    "SESSION": sessionId,
    "Referer": "http://mobile.tc.cqupt.edu.cn/",
    "Origin": "http://mobile.tc.cqupt.edu.cn/",
    "X-Requested-With": "XMLHttpRequest",
  };

  String _getDeviceId(AuthCredential credential) {
    return DeterministicUuidUtil.generate(credential.id);
  }

  bool _checkResult(Response r) {
    return r.data["status"] == "on_call" || r.data["status"] == "on_call_fine";
  }

  /// 获取签到事件
  Future<List<RollcallModel>?> getCheckinEvents(
    AuthCredential credential,
  ) async {
    try {
      final r1 = await _dio.get(
        apiGetEvent,
        options: Options(headers: _getHeader(credential.token)),
      );
      if (r1.statusCode != 200 || r1.data["rollcalls"] == null) return null;
      return List.from(
        r1.data["rollcalls"],
      ).map((v) => RollcallModel.fromJson(v)).toList();
    } catch (e) {
      return null;
    }
  }

  /// 雷达签到原始接口
  Future<double?> rawCheckinRadar(
    AuthCredential credential,
    String id,
    Coordinate coord,
    double speed,
    double accuracy,
  ) async {
    try {
      final r = await _dio.put(
        apiCheckinRadar(id),
        data: {
          "deviceId": credential.ext?["uuid"] ?? _getDeviceId(credential),
          "longitude": coord.lng,
          "latitude": coord.lat,
          "speed": speed,
          "accuracy": accuracy,
        },
        options: Options(
          headers: _getHeader(credential.token),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return r.data["distance"];
    } catch (e) {
      return null;
    }
  }

  /// 探测雷达签到坐标
  Future<List<Coordinate>> detectCheckinCoord(
    AuthCredential credential,
    String id,
    Coordinate auxiliaryA, // 辅助点A
    Coordinate auxiliaryB, // 辅助点B
  ) async {
    final List<Future<double?>> futures = [
      rawCheckinRadar(credential, id, auxiliaryA, 0.0, 30),
      rawCheckinRadar(credential, id, auxiliaryB, 0.0, 30),
    ];
    final distances = await Future.wait(futures);
    if (distances.first == null || distances.last == null) return List.empty();
    return findCircleIntersections(
      auxiliaryA,
      distances.first!,
      auxiliaryB,
      distances.last!,
    );
  }

  /// PIN签到
  Future<bool> checkinPin(
    AuthCredential credential,
    String id,
    String pin,
  ) async {
    try {
      final r = await _dio.put(
        apiCheckinPin(id),
        data: {
          "deviceId": credential.ext?["uuid"] ?? _getDeviceId(credential),
          "numberCode": pin,
        },
        options: Options(headers: _getHeader(credential.token)),
      );
      return _checkResult(r);
    } catch (e) {
      return false;
    }
  }

  /// 暴力PIN签到
  Future<String?> checkinPinCrack(AuthCredential credential, String id) async {
    try {
      return await bruteForcePassword(
        url: apiCheckinPin(id),
        headers: _getHeader(credential.token),
        deviceId: credential.ext?["uuid"] ?? _getDeviceId(credential),
      );
    } catch (e) {
      return null;
    }
  }

  /// 雷达签到
  Future<bool> checkinRadar(
    AuthCredential credential,
    String id,
    Coordinate coord,
    double speed,
    double accuracy,
  ) async {
    return ((await rawCheckinRadar(credential, id, coord, speed, accuracy)) !=
        null);
  }

  /// 二维码签到
  Future<bool> checkinQr(
    AuthCredential credential,
    String id,
    String data,
  ) async {
    try {
      final r = await _dio.put(
        apiCheckinQr(id),
        data: {
          "deviceId": credential.ext?["uuid"] ?? _getDeviceId(credential),
          "data": data,
        },
        options: Options(headers: _getHeader(credential.token)),
      );
      return _checkResult(r);
    } catch (e) {
      return false;
    }
  }

  /// 批量PIN签到
  Future<List<bool>> checkinAllPin(
    List<AuthCredential> credentials,
    String id,
    String pin,
  ) async {
    try {
      final List<Future<bool>> futures = credentials
          .map((credential) => checkinPin(credential, id, pin))
          .toList();
      return await Future.wait(futures);
    } catch (e) {
      return List.empty();
    }
  }

  /// 批量PIN爆破签到
  Future<List<bool>> checkinAllPinCrack(
    List<AuthCredential> credentials,
    String id,
  ) async {
    final pin = await checkinPinCrack(credentials.first, id);
    if (pin == null) return List.empty();
    return [true, ...(await checkinAllPin(credentials.sublist(1), id, pin))];
  }

  /// 批量二维码签到
  Future<List<bool>> checkinAllQr(
    List<AuthCredential> credentials,
    String id,
    String data,
  ) async {
    try {
      final List<Future<bool>> futures = credentials
          .map((credential) => checkinQr(credential, id, data))
          .toList();
      return await Future.wait(futures);
    } catch (e) {
      return List.empty();
    }
  }

  /// 批量雷达签到
  Future<List<bool>> checkinAllRadar(
    List<AuthCredential> credentials,
    String id,
    Coordinate coord,
    double speed,
    double accuracy,
  ) async {
    try {
      final List<Future<bool>> futures = credentials
          .map(
            (credential) =>
                checkinRadar(credential, id, coord, speed, accuracy),
          )
          .toList();
      return await Future.wait(futures);
    } catch (e) {
      return List.empty();
    }
  }
}
