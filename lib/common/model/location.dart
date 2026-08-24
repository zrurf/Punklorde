import 'package:flutter_bmflocation/flutter_bmflocation.dart';

enum CoordinateType {
  wgs84, // GPS坐标系
  gcj02, // 火星坐标系
  bd09ll, // 百度经纬度坐标系
  unknown, // 未知坐标系
}

enum LocationPurpose {
  single, // 单次定位
  sport, // 运动定位
  other, // 其他
}

extension CoordinateTypeExtension on CoordinateType {
  BMFLocationCoordType toBDMapCoordinateType() {
    switch (this) {
      case .wgs84:
        return .wgs84;
      case .gcj02:
        return .gcj02;
      case .bd09ll:
        return .bd09ll;
      default:
        return .wgs84;
    }
  }
}

extension LocationPurposeExtension on LocationPurpose {
  BMFLocationPurpose toBDMapLocationPurpose() {
    switch (this) {
      case .single:
        return .signIn;
      case .sport:
        return .transport;
      default:
        return .other;
    }
  }
}

// 坐标
class Coordinate {
  final double lat;
  final double lng;
  final double? alt;

  const Coordinate({required this.lat, required this.lng, this.alt});
}

// 轨迹点
class TrajPoint {
  final Coordinate coordinate;
  final DateTime time;

  const TrajPoint({required this.coordinate, required this.time});
}
