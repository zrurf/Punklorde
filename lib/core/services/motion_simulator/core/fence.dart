import '../model.dart';

/// 电子围栏点
class GeoFencePoint {
  final double latitude;
  final double longitude;

  const GeoFencePoint({required this.latitude, required this.longitude});
}

/// 电子围栏（支持空洞）
class GeoFence {
  final List<GeoFencePoint> outerBoundary;
  final List<List<GeoFencePoint>> holes; // 空洞列表

  const GeoFence({required this.outerBoundary, this.holes = const []});

  /// 检查点是否在围栏内（考虑空洞）
  bool containsPoint(TrajectoryPoint point) {
    if (!_isPointInPolygon(point, outerBoundary)) {
      return false;
    }

    // 检查是否在空洞内
    for (final hole in holes) {
      if (_isPointInPolygon(point, hole)) {
        return false; // 在空洞内，返回false
      }
    }

    return true;
  }

  /// 纠正点到最近的边界
  TrajectoryPoint correctPoint(TrajectoryPoint point) {
    if (containsPoint(point)) {
      return point;
    }

    // 找到最近的边界点
    double minDistance = double.infinity;
    TrajectoryPoint? closestPoint;

    // 检查外边界
    for (final fencePoint in outerBoundary) {
      final distance = point.distanceTo(
        TrajectoryPoint(
          latitude: fencePoint.latitude,
          longitude: fencePoint.longitude,
        ),
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = TrajectoryPoint(
          latitude: fencePoint.latitude,
          longitude: fencePoint.longitude,
        );
      }
    }

    return closestPoint ?? point;
  }

  /// 射线法判断点是否在多边形内
  bool _isPointInPolygon(TrajectoryPoint point, List<GeoFencePoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    final double x = point.longitude;
    final double y = point.latitude;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final double xi = polygon[i].longitude;
      final double yi = polygon[i].latitude;
      final double xj = polygon[j].longitude;
      final double yj = polygon[j].latitude;

      final bool intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
    }

    return inside;
  }
}
