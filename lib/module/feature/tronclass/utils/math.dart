import 'dart:math';

import 'package:punklorde/common/model/location.dart';

/// 计算地球上两个圆的交点（半径 ≤ 10km，忽略海拔）
/// 参数：
///   c1, c2: 圆心坐标（纬度/经度，度）
///   r1, r2: 半径（米）
/// 返回：
///   交点列表（0、1 或 2 个），当两圆重合时返回空列表（无穷多交点）
List<Coordinate> findCircleIntersections(
  Coordinate c1,
  double r1,
  Coordinate c2,
  double r2,
) {
  const double eps = 1e-9; // 数值容差
  const double R = 6371000.0; // 地球平均半径（米）

  // 1. 将经纬度转换为弧度
  final double lat1 = c1.lat * pi / 180.0;
  final double lng1 = c1.lng * pi / 180.0;
  final double lat2 = c2.lat * pi / 180.0;
  final double lng2 = c2.lng * pi / 180.0;

  // 2. 球面距离（Haversine 公式），用于快速判断有无交点
  final double dLat = lat2 - lat1;
  final double dLng = lng2 - lng1;
  final double aH =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
  final double cH = 2 * atan2(sqrt(aH), sqrt(1 - aH));
  final double sphereDist = R * cH; // 球面距离（米）

  // 无交点：相离或内含（含同心但半径不等）
  if (sphereDist > r1 + r2 + eps || sphereDist < (r1 - r2).abs() - eps) {
    return [];
  }

  // 圆心重合且半径相等 -> 无穷多交点（返回空）
  if (sphereDist < eps && (r1 - r2).abs() < eps) {
    return [];
  }

  // 3. 平面投影（以 c1 为原点，局部平面坐标）
  final double dx = R * cos(lat1) * (lng2 - lng1);
  final double dy = R * (lat2 - lat1);
  final double d = sqrt(dx * dx + dy * dy); // 平面距离

  // 再次使用平面距离检查（数值保护）
  if (d > r1 + r2 + eps || d < (r1 - r2).abs() - eps) {
    return [];
  }

  // 4. 平面几何求交点
  final double a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
  double h2 = r1 * r1 - a * a;
  if (h2 < -eps) return [];
  if (h2 < 0) h2 = 0;
  final double h = sqrt(h2);

  // 中点坐标（相对于 c1 的局部平面）
  final double x0 = dx * a / d;
  final double y0 = dy * a / d;

  List<Coordinate> results = [];

  // 将局部平面坐标转换回经纬度
  void addPoint(double x, double y) {
    final double latRad = lat1 + y / R;
    final double lngRad = lng1 + x / (R * cos(lat1));
    results.add(Coordinate(lat: latRad * 180 / pi, lng: lngRad * 180 / pi));
  }

  if (h < eps) {
    // 相切，一个交点
    addPoint(x0, y0);
  } else {
    // 两个交点
    final double xOffset = -dy * (h / d);
    final double yOffset = dx * (h / d);
    addPoint(x0 + xOffset, y0 + yOffset);
    addPoint(x0 - xOffset, y0 - yOffset);
  }

  return results;
}
