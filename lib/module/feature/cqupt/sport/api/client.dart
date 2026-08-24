import 'package:dio/dio.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/endpoint.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/interceptor.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/model/sport.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/platform/cqupt/interceptor/sport_portal.dart';
import 'package:punklorde/utils/etc/time.dart';

class ApiClient {
  late final Dio _dio;

  late final CquptSportPortalInterceptor _interceptor;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    // 添加拦截器
    _dio.interceptors.add(AuthInterceptor(_dio));

    _interceptor = CquptSportPortalInterceptor();
  }

  // 开始运动
  Future<String?> startSport(String placeName, String placeCode) async {
    try {
      final response = await _dio.post(
        apiSportStart(),
        data: StartSportModel(
          placeName: placeName,
          placeCode: placeCode,
        ).toJson(),
      );
      if (response.data['code'] == '10200') {
        return response.data['data'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 结束运动
  Future<bool> endSport(String sportId) async {
    try {
      final response = await _dio.post(apiSportEnd(sportId));
      return (response.data['code'] == '10200');
    } catch (e) {
      return false;
    }
  }

  // 获取进行中的运动记录列表（仅限今天、endTime 为 null 的未完成记录，用于续跑）
  Future<List<WxSportRecord>> getWxSportRecords(
    int pageNo,
    int pageSize,
  ) async {
    try {
      final response = await _dio.get(apiSportGetWxRecords(pageNo, pageSize));
      if (response.data['code'] != '10200') return [];
      final data = response.data['data'];
      final list = (data is Map<String, dynamic>) ? data['list'] : null;
      if (list is List<dynamic>) {
        final now = DateTime.now();
        bool startedToday(WxSportRecord v) {
          if (v.startTime == null) return false;
          final d = parseDate(v.startTime!);
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }

        return list
            .whereType<Map<String, dynamic>>()
            .map(WxSportRecord.fromJson)
            .where(
              (v) =>
                  v.sportRecordNo.isNotEmpty &&
                  v.endTime == null &&
                  startedToday(v),
            )
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 获取运动区域（用于定位匹配运动场）
  Future<List<SportArea>> getSportAreas() async {
    try {
      final response = await _dio.get(apiSportArea());
      if (response.data['code'] != '10200') return [];
      final data = response.data['data'];
      if (data is List<dynamic>) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SportArea.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 继续运动
  Future<bool> continueSport(String sportRecordNo) async {
    try {
      final response = await _dio.get(apiSportContinue(sportRecordNo));
      return (response.data['code'] == '10200');
    } catch (e) {
      return false;
    }
  }

  // 获取运动记录信息（含已上传轨迹点）
  Future<SportInfoResult?> getSportInfo(String sportRecordNo) async {
    try {
      final response = await _dio.get(apiSportInfo(sportRecordNo));
      if (response.data['code'] != '10200') return null;
      return SportInfoResult.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  // 上传运动数据
  Future<UploadRecordResult?> uploadPoint(
    List<TrajPoint> points,
    String placeName,
    String placeCode,
    String sportId,
  ) async {
    try {
      final response = await _dio.post(
        apiSportUpload(),
        data: UploadRecordModel(
          sportRecordNo: sportId,
          sportPointList: points
              .map(
                (e) => UploadPointModel(
                  longitude: e.coordinate.lng,
                  latitude: e.coordinate.lat,
                  collectTime: e.time,
                  isValid: 1,
                  placeName: placeName,
                  placeCode: placeCode,
                ),
              )
              .toList(),
        ).toJson(),
      );
      if (response.data['code'] == '10200') {
        return UploadRecordResult.fromJson(response.data["data"]);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 上传运动数据
  Future<bool> retryUploadPoints(
    List<TrajPoint> points,
    String placeName,
    String placeCode,
    String sportId,
  ) async {
    try {
      final response = await _dio.post(
        apiSportUploadRetry(),
        data: UploadRecordModel(
          sportRecordNo: sportId,
          sportPointList: points
              .map(
                (v) => UploadPointModel(
                  longitude: v.coordinate.lng,
                  latitude: v.coordinate.lat,
                  collectTime: v.time,
                  isValid: 1,
                  placeName: placeName,
                  placeCode: placeCode,
                ),
              )
              .toList(),
        ).toJson(),
      );
      return (response.data['code'] == '10200');
    } catch (e) {
      return false;
    }
  }

  // 获取运动记录
  Future<List<RecordResult>> getSportRecords() async {
    try {
      final response = await _dio.get(apiSportGetRecords());
      final data = response.data['data'];
      if (data is List<dynamic>) {
        return data.map((v) => RecordResult.fromJson(v)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<SportStatistics?> getSportStat() async {
    if (featPortalCredential.value == null) return null;
    _interceptor.setToken(featPortalCredential.value!.token);
    _dio.interceptors.add(_interceptor);
    try {
      final response = await _dio.get(apiSportStat());
      if (response.statusCode != 200 || response.data['code'] != "10200") {
        return null;
      }
      final data = response.data['data'];
      return SportStatistics.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(_interceptor);
    }
  }

  Future<List<SportFaceRecord>?> getSportFaceRecordList(DateTime date) async {
    if (featPortalCredential.value == null) return null;
    final dateStr = formatDay(date);
    _interceptor.setToken(featPortalCredential.value!.token);
    _dio.interceptors.add(_interceptor);
    try {
      final response = await _dio.get(apiSportFace(dateStr));
      if (response.statusCode != 200 || response.data['code'] != "10200") {
        return null;
      }
      final data = response.data['data'];
      if (data is List<dynamic>) {
        return data.map((v) => SportFaceRecord.fromJson(v)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return null;
    } finally {
      _dio.interceptors.remove(_interceptor);
    }
  }
}
