import 'package:flutter_bmflocation/flutter_bmflocation.dart';

enum CoordinateType {
  WGS84, // GPS坐标系
  GCJ02, // 火星坐标系
  BD09LL, // 百度经纬度坐标系
  UNKNOWN, // 未知坐标系
}

enum LocationPurpose {
  single, // 单次定位
  sport, // 运动定位
  other, // 其他
}

extension CoordinateTypeExtension on CoordinateType {
  BMFLocationCoordType toBDMapCoordinateType() {
    switch (this) {
      case .WGS84:
        return .wgs84;
      case .GCJ02:
        return .gcj02;
      case .BD09LL:
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

class Coordinate {
  final double lat;
  final double lng;
  final double? alt;

  const Coordinate({required this.lat, required this.lng, this.alt});
}

class TrajPoint {
  final Coordinate coordinate;
  final DateTime time;

  const TrajPoint({required this.coordinate, required this.time});
}
