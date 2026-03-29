// 开始运动请求体
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
  final num longitude;
  final num latitude;
  final DateTime collectTime;
  final String isValid;

  const PointResult({
    required this.longitude,
    required this.latitude,
    required this.collectTime,
    required this.isValid,
  });

  factory PointResult.fromJson(Map<String, dynamic> json) {
    return PointResult(
      longitude: json['longitude'],
      latitude: json['latitude'],
      collectTime: parseDate(json['collectTime']),
      isValid: json['isValid'],
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
