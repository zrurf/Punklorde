import 'package:dio/dio.dart';
import 'package:punklorde/common/models/auth.dart';
import 'package:punklorde/common/utils/etc/device.dart';
import 'package:punklorde/common/models/location.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/const/url.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/model/api.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/utils/date.dart';

class ApiClient {
  final Dio _dio;
  final String userAgent = getUA(.wxapplet);
  AuthCredential auth;

  ApiClient(this.auth) : _dio = Dio();

  Future<String?> startMotion(String pName, String pCode) async {
    try {
      final response = await _dio.post(
        startMotionUrl,
        data: {"placeCode": pCode, "placeName": pName},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": userAgent,
            "token": auth.token,
          },
        ),
      );
      print("_INFO: ${response.data}");

      // 登录失效处理
      if (response.data["code"] == "40401") {
        if (await refreshToken()) {
          return await startMotion(pName, pCode);
        } else {
          return null;
        }
      }
      return response.data["data"];
    } catch (e) {
      print("_ERROR: $e");
      return null;
    }
  }

  Future<UploadPointRedult?> uploadPoint(
    List<TrajPoint> points,
    String pName,
    String pCode,
    String sCode,
  ) async {
    try {
      final response = await _dio.post(
        uploadUrl,
        data: {
          "sportRecordNo": sCode,
          "placeCode": pCode,
          "placeName": pName,
          "sportPointList": points
              .map(
                (p) => {
                  "sportRecordNo": sCode,
                  "longitude": p.coordinate.lng,
                  "latitude": p.coordinate.lat,
                  "placeName": pName,
                  "placeCode": pCode,
                  "collectTime": formatDate(p.time),
                  "isValid": "1",
                },
              )
              .toList(),
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": userAgent,
            "token": auth.token,
          },
          receiveTimeout: Duration(seconds: 10),
        ),
      );
      print("_INFO: ${response.data}");
      // 登录失效处理
      if (response.data["code"] == "40401") {
        if (await refreshToken()) {
          return await uploadPoint(points, pName, pCode, sCode);
        } else {
          return null;
        }
      }
      return UploadPointRedult.fromJson(response.data["data"]);
    } catch (e) {
      print("_ERROR: $e");
      return null;
    }
  }

  Future<bool> endMotion(String sCode) async {
    try {
      var response = await _dio.post(
        endMotionUrl + sCode,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": userAgent,
            "token": auth.token,
          },
          receiveTimeout: Duration(seconds: 20),
        ),
      );
      // 登录失效处理
      if (response.data["code"] == "40401") {
        if (await refreshToken()) {
          return await endMotion(sCode);
        } else {
          return false;
        }
      }
    } catch (e) {
      print("_ERROR: $e");
      return false;
    }
    return true;
  }

  Future<bool> refreshToken() async {
    await authManager.refreshAuth(auth.type);
    var newAuth = authManager.getAuth(auth.type);
    if (newAuth != null) {
      auth = newAuth;
      return true;
    }
    return false;
  }
}
