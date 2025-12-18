import 'package:dio/dio.dart';
import 'package:punklorde/common/models/location.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/const/const.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/const/url.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/model/api.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/model/auth.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/utils/date.dart';

final _dio = Dio();

Future<ModTongtianAuth?> getTongtianAuth(String openid) async {
  try {
    final response = await _dio.get(
      '$loginUrl?sxCode=&openid=$openid&phoneType=Google_Android',
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "User-Agent": appletUserAgent,
        },
      ),
    );
    print("_INFO: ${response.data}");
    return ModTongtianAuth.fromJson(response.data["data"]);
  } catch (e) {
    print("_ERROR: $e");
    return null;
  }
}

class ApiClient {
  final Dio _dio;
  final String userAgent = appletUserAgent;
  final ModTongtianAuth auth;

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
      return UploadPointRedult.fromJson(response.data["data"]);
    } catch (e) {
      print("_ERROR: $e");
      return null;
    }
  }

  Future<bool> endMotion(String sCode) async {
    try {
      await _dio.post(
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
    } catch (e) {
      print("_ERROR: $e");
      return false;
    }
    return true;
  }
}
