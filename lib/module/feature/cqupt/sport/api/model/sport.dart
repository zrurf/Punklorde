// 开始运动请求体
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/cqupt/sport/utils/time.dart';

class StartSportModel {
  final String placeName;
  final String placeCode;

  const StartSportModel({required this.placeName, required this.placeCode});

  Map<String, dynamic> toJson() => {
    "placeName": placeName,
    "placeCode": placeCode,
  };
}

// 上传运动点请求体
class UploadPointModel {
  final double longitude;
  final double latitude;
  final DateTime collectTime;
  final int isValid; // 1-有效, 2-无效(禁区)
  final String placeName;
  final String placeCode;

  const UploadPointModel({
    required this.longitude,
    required this.latitude,
    required this.collectTime,
    required this.isValid,
    required this.placeName,
    required this.placeCode,
  });

  Map<String, dynamic> toJson() => {
    "longitude": longitude,
    "latitude": latitude,
    "collectTime": formatDate(collectTime),
    "isValid": isValid.toString(),
    "placeName": placeName,
    "placeCode": placeCode,
  };
}

// 运动轨迹点
class PointResult {
  final double longitude;
  final double latitude;
  final DateTime collectTime;
  final String isValid;

  const PointResult({
    required this.longitude,
    required this.latitude,
    required this.collectTime,
    required this.isValid,
  });

  /// 坐标可能为字符串（/sportRecord/info 返回）或数字
  static double _parseCoord(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory PointResult.fromJson(Map<String, dynamic> json) {
    return PointResult(
      longitude: _parseCoord(json['longitude']),
      latitude: _parseCoord(json['latitude']),
      collectTime: parseDate(
        json['collectTime']?.toString() ?? '1970-01-01 00:00:00',
      ),
      isValid: json['isValid']?.toString() ?? '1',
    );
  }
}

// 上传运动记录请求体
class UploadRecordModel {
  final String sportRecordNo;
  final List<UploadPointModel> sportPointList;

  const UploadRecordModel({
    required this.sportRecordNo,
    required this.sportPointList,
  });

  Map<String, dynamic> toJson() => {
    "sportRecordNo": sportRecordNo,
    "sportPointList": sportPointList.map((e) => e.toJson()).toList(),
  };
}

// 上传运动记录结果
class UploadRecordResult {
  final num timeConsuming;
  final num mileage;
  final num expiredCountInForbiddenArea;

  const UploadRecordResult({
    required this.timeConsuming,
    required this.mileage,
    required this.expiredCountInForbiddenArea,
  });

  factory UploadRecordResult.fromJson(Map<String, dynamic> json) {
    return UploadRecordResult(
      timeConsuming: json['timeConsuming'],
      mileage: json['mileage'],
      expiredCountInForbiddenArea: json['expiredCountInForbiddenArea'],
    );
  }
}

// 进行中的运动记录（对应小程序 getWxSportPage）
class WxSportRecord {
  final String sportRecordNo;
  final String? placeCode;
  final String? placeName;

  /// 开始时间（yyyy-MM-dd HH:mm:ss）
  final String? startTime;

  /// 里程（km）
  final double mileage;

  /// 耗时（秒）
  final double timeConsuming;

  /// 结束时间（null 表示未结束，可续跑）
  final String? endTime;

  const WxSportRecord({
    required this.sportRecordNo,
    this.placeCode,
    this.placeName,
    this.startTime,
    required this.mileage,
    required this.timeConsuming,
    this.endTime,
  });

  factory WxSportRecord.fromJson(Map<String, dynamic> json) {
    return WxSportRecord(
      sportRecordNo: json['sportRecordNo']?.toString() ?? '',
      placeCode: json['placeCode']?.toString(),
      placeName: json['placeName']?.toString(),
      startTime: json['startTime']?.toString(),
      mileage: (json['mileage'] as num?)?.toDouble() ?? 0,
      timeConsuming: (json['timeConsuming'] as num?)?.toDouble() ?? 0,
      endTime: json['endTime']?.toString(),
    );
  }
}

// 运动区域（对应小程序 getAllArea，用于定位匹配运动场）
class SportArea {
  final String? placeCode;
  final String? placeName;
  final String? areaFuncCode;

  /// 区域多边形顶点
  final List<Coordinate> areaPointList;

  const SportArea({
    this.placeCode,
    this.placeName,
    this.areaFuncCode,
    required this.areaPointList,
  });

  factory SportArea.fromJson(Map<String, dynamic> json) {
    return SportArea(
      placeCode: json['placeCode']?.toString(),
      placeName: json['placeName']?.toString(),
      areaFuncCode: json['areaFuncCode']?.toString(),
      areaPointList: (json['areaPointList'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => Coordinate(
              lat: (p['latitude'] as num?)?.toDouble() ?? 0,
              lng: (p['longitude'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
    );
  }
}

// 运动记录信息（对应小程序 getSportRecordInfo）
class SportInfoResult {
  /// 里程（km）
  final double mileage;

  /// 耗时（秒）
  final double timeConsuming;

  /// 已上传的轨迹点
  final List<PointResult> points;

  const SportInfoResult({
    required this.mileage,
    required this.timeConsuming,
    required this.points,
  });

  factory SportInfoResult.fromJson(Map<String, dynamic> json) {
    return SportInfoResult(
      mileage: (json['mileage'] as num?)?.toDouble() ?? 0,
      timeConsuming: (json['timeConsuming'] as num?)?.toDouble() ?? 0,
      points: (json['points'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PointResult.fromJson)
          .toList(),
    );
  }
}

// 运动结果接口
class RecordResult {
  final String sportsResultNo;
  final String sportsType;
  final bool isValid;
  final String sportsStartTime;
  final String sportsEndTime;
  final String placeName;
  final String? reckonType;
  final double duration;
  final double distance;
  final bool isAppeal;
  final String? reason;

  RecordResult({
    required this.sportsResultNo,
    required this.sportsType,
    required this.isValid,
    required this.sportsStartTime,
    required this.sportsEndTime,
    required this.placeName,
    this.reckonType,
    required this.duration,
    required this.distance,
    required this.isAppeal,
    this.reason,
  });

  factory RecordResult.fromJson(Map<String, dynamic> json) {
    return RecordResult(
      sportsResultNo: json['sportsResultNo'] as String,
      sportsType: json['sportsType'] as String,
      isValid: json['isValid'] == '1',
      sportsStartTime: json['sportsStartTime'] as String,
      sportsEndTime: json['sportsEndTime'] as String,
      placeName: json['placeName'] as String,
      reckonType: json['reckonType'] as String?,
      duration: (json['duration'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      isAppeal: json['isAppeal'] != '0',
      reason: json['reason'] as String?,
    );
  }
}
