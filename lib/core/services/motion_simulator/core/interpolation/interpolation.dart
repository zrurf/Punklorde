import 'dart:math';
import '../../model.dart';

/// Catmull-Rom曲线插值器
class CatmullRomInterpolator {
  /// 执行Catmull-Rom插值
  /// [t]: 插值参数，范围[0, 1]
  /// [p0, p1, p2, p3]: 四个控制点
  static TrajectoryPoint interpolate({
    required double t,
    required TrajectoryPoint p0,
    required TrajectoryPoint p1,
    required TrajectoryPoint p2,
    required TrajectoryPoint p3,
    double tension = 0.5,
  }) {
    final t2 = t * t;
    final t3 = t2 * t;

    // Catmull-Rom矩阵系数
    final m00 = -tension * t3 + 2 * tension * t2 - tension * t;
    final m01 = (2 - tension) * t3 + (tension - 3) * t2 + 1;
    final m02 = (tension - 2) * t3 + (3 - 2 * tension) * t2 + tension * t;
    final m03 = tension * t3 - tension * t2;

    // 计算插值点
    final lat =
        m00 * p0.latitude +
        m01 * p1.latitude +
        m02 * p2.latitude +
        m03 * p3.latitude;

    final lon =
        m00 * p0.longitude +
        m01 * p1.longitude +
        m02 * p2.longitude +
        m03 * p3.longitude;

    // 可选：插值海拔和航向角
    double? altitude;
    if (p0.altitude != null &&
        p1.altitude != null &&
        p2.altitude != null &&
        p3.altitude != null) {
      altitude =
          m00 * p0.altitude! +
          m01 * p1.altitude! +
          m02 * p2.altitude! +
          m03 * p3.altitude!;
    }

    double? heading;
    if (p0.heading != null &&
        p1.heading != null &&
        p2.heading != null &&
        p3.heading != null) {
      // 处理航向角的角度循环
      final angles = [p0.heading!, p1.heading!, p2.heading!, p3.heading!];
      heading = _interpolateAngles(angles, [m00, m01, m02, m03]);
    }

    return TrajectoryPoint(
      latitude: lat,
      longitude: lon,
      altitude: altitude,
      heading: heading,
    );
  }

  /// 处理角度插值，考虑360°循环
  static double _interpolateAngles(List<double> angles, List<double> weights) {
    double sumSin = 0;
    double sumCos = 0;

    for (int i = 0; i < angles.length; i++) {
      final rad = angles[i] * pi / 180;
      sumSin += sin(rad) * weights[i];
      sumCos += cos(rad) * weights[i];
    }

    final result = atan2(sumSin, sumCos) * 180 / pi;
    return result >= 0 ? result : result + 360;
  }

  /// 批量插值
  static List<TrajectoryPoint> interpolatePath({
    required List<TrajectoryPoint> points,
    int segmentsPerInterval = 10,
    double tension = 0.5,
  }) {
    if (points.length < 4) {
      return List.from(points);
    }

    final interpolatedPoints = <TrajectoryPoint>[];

    // 添加第一个点
    interpolatedPoints.add(points[0]);

    for (int i = 0; i < points.length - 1; i++) {
      // 获取四个控制点，处理边界情况
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i == points.length - 2 ? points[i + 1] : points[i + 2];

      // 在p1和p2之间插值
      for (int j = 1; j <= segmentsPerInterval; j++) {
        final t = j / segmentsPerInterval;
        final interpolatedPoint = interpolate(
          t: t,
          p0: p0,
          p1: p1,
          p2: p2,
          p3: p3,
          tension: tension,
        );
        interpolatedPoints.add(interpolatedPoint);
      }
    }

    // 确保最后一个点被添加
    if (interpolatedPoints.last != points.last) {
      interpolatedPoints.add(points.last);
    }

    return interpolatedPoints;
  }
}
