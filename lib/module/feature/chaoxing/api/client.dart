import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/chaoxing/api/endpoint.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:punklorde/module/feature/chaoxing/utils/response.dart';
import 'package:punklorde/module/platform/chaoxing/utils/ua.dart';
import 'package:punklorde/utils/uuid.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        connectTimeout: const Duration(seconds: 10),
      ),
    );
  }

  /// 获取课程列表
  Future<CourseResponse?> getCourseList(AuthCredentialCache cred) async {
    CookieManager cookieManager = CookieManager(cred.cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final response = await _dio.get(
        apiCourseList,
        options: Options(headers: {"User-Agent": cred.credential.ext!["ua"]}),
      );
      if (response.statusCode != 200) return null;
      final data = json.decode(response.data);
      if (data == null) return null;
      return CourseResponse.fromJson(data);
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 获取活动
  Future<List<ActiveResult>?> getActives(
    AuthCredentialCache cred,
    String courseId,
    String classId,
  ) async {
    CookieManager cookieManager = CookieManager(cred.cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final r = await _dio.get(
        apiActiveList(courseId, classId),
        options: Options(headers: {"User-Agent": cred.credential.ext!["ua"]}),
      );
      return ActiveResponseParser.parseListFromResponse(r.data);
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  Future<bool> checkinDone(AuthCredentialCache cred, String activeId) async {
    CookieManager cookieManager = CookieManager(cred.cookie);
    _dio.interceptors.add(cookieManager);
    try {
      final r = await _dio.get(
        apiSignResult(activeId),
        options: Options(headers: {"User-Agent": cred.credential.ext!["ua"]}),
      );
      return (r.statusCode == 200 && r.data?["data"]?["status"] == 1);
    } catch (e) {
      return false;
    } finally {
      _dio.interceptors.remove(cookieManager);
    }
  }

  /// 二维码签到
  Future<List<bool>> checkinAllQr(
    List<AuthCredentialCache> credentials,
    String id,
    String enc,
    String enc2,
  ) async {
    final Map<String, String> param = {
      "appType": "15",
      "fid": "0",
      "activeId": id,
      "latitude": "-1",
      "longitude": "-1",
      "vpProbability": "-1",
      "enc": enc,
      "enc2": enc2,
      "uid": "",
      "name": "",
      "deviceCode": "",
    };
    final List<bool> result = List.filled(credentials.length, false);
    for (final (i, cred) in credentials.indexed) {
      final deviceCode = genDeviceFingerprint(
        cred.credential.ext?["device_id"] ??
            DeterministicUuidUtil.generate(cred.credential.id),
      );
      final CookieManager cookie = CookieManager(cred.cookie);
      _dio.interceptors.add(cookie);
      param["uid"] = cred.credential.id;
      param["name"] = cred.credential.name;
      param["deviceCode"] = deviceCode;
      try {
        final ua = cred.credential.ext!["ua"];
        final r1 = await _dio.get(
          apiCommonSign,
          queryParameters: param,
          options: Options(headers: {"User-Agent": ua}),
        );
        if (r1.statusCode != 200) continue;
        final r2 = await _dio.get(
          apiSignResult(id),
          options: Options(headers: {"User-Agent": ua}),
        );
        result[i] = (r2.statusCode == 200 && r2.data?["data"]?["status"] == 1);
      } catch (e) {
        continue;
      } finally {
        _dio.interceptors.remove(cookie);
      }
    }
    return result;
  }

  /// 签到码签到
  Future<List<bool>> checkinAllCode(
    List<AuthCredentialCache> credentials,
    String id,
    String code,
  ) async {
    final Map<String, String> param = {
      "appType": "15",
      "fid": "0",
      "activeId": id,
      "latitude": "-1",
      "longitude": "-1",
      "vpProbability": "-1",
      "signCode": code,
      "uid": "",
      "name": "",
      "deviceCode": "",
    };
    final List<bool> result = List.filled(credentials.length, false);

    for (final (i, cred) in credentials.indexed) {
      final deviceCode = genDeviceFingerprint(
        cred.credential.ext?["device_id"] ??
            DeterministicUuidUtil.generate(cred.credential.id),
      );
      final CookieManager cookie = CookieManager(cred.cookie);
      _dio.interceptors.add(cookie);
      param["uid"] = cred.credential.id;
      param["name"] = cred.credential.name;
      param["deviceCode"] = deviceCode;
      try {
        final ua = cred.credential.ext!["ua"];

        if (i == 0) {
          final r1 = await _dio.get(
            apiSignCodeCheck(id, code),
            options: Options(headers: {"User-Agent": ua}),
          );
          if (r1.data["result"] != 1) {
            return result;
          }
        }

        final r2 = await _dio.get(
          apiCommonSign,
          queryParameters: param,
          options: Options(headers: {"User-Agent": ua}),
        );
        if (r2.statusCode != 200) continue;
        final r3 = await _dio.get(
          apiSignResult(id),
          options: Options(headers: {"User-Agent": ua}),
        );
        result[i] = (r3.statusCode == 200 && r3.data?["data"]?["status"] == 1);
      } catch (e) {
        continue;
      } finally {
        _dio.interceptors.remove(cookie);
      }
    }
    return result;
  }

  /// 位置签到
  Future<List<bool>> checkinAllPos(
    List<AuthCredentialCache> credentials,
    String id,
    Coordinate pos,
  ) async {
    final Map<String, String> param = {
      "appType": "15",
      "fid": "0",
      "activeId": id,
      "latitude": pos.lat.toStringAsFixed(6),
      "longitude": pos.lng.toStringAsFixed(6),
      "vpProbability": "-1",
      "vpStrategy": "",
      "ifTiJiao": "1",
      "ifCFP": "0",
      "uid": "",
      "name": "",
      "deviceCode": "",
    };
    final List<bool> result = List.filled(credentials.length, false);
    for (final (i, cred) in credentials.indexed) {
      final deviceCode = genDeviceFingerprint(
        cred.credential.ext?["device_id"] ??
            DeterministicUuidUtil.generate(cred.credential.id),
      );
      final CookieManager cookie = CookieManager(cred.cookie);
      _dio.interceptors.add(cookie);
      param["uid"] = cred.credential.id;
      param["name"] = cred.credential.name;
      param["deviceCode"] = deviceCode;
      try {
        final ua = cred.credential.ext!["ua"];
        final r1 = await _dio.get(
          apiCommonSign,
          queryParameters: param,
          options: Options(headers: {"User-Agent": ua}),
        );
        if (r1.statusCode != 200) continue;
        final r2 = await _dio.get(
          apiSignResult(id),
          options: Options(headers: {"User-Agent": ua}),
        );
        result[i] = (r2.statusCode == 200 && r2.data?["data"]?["status"] == 1);
      } catch (e) {
        continue;
      } finally {
        _dio.interceptors.remove(cookie);
      }
    }
    return result;
  }
}
