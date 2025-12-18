import 'package:flutter_test/flutter_test.dart';
import 'package:punklorde/core/services/motion_simulator/model.dart';
import 'package:punklorde/core/services/motion_simulator/core/interpolation/interpolation.dart';

void main() {
  group('CatmullRomInterpolator', () {
    late List<TrajectoryPoint> testPoints;

    setUp(() {
      testPoints = [
        TrajectoryPoint(latitude: 0, longitude: 0),
        TrajectoryPoint(latitude: 1, longitude: 1),
        TrajectoryPoint(latitude: 2, longitude: 0),
        TrajectoryPoint(latitude: 3, longitude: 1),
      ];
    });

    test('should interpolate between two points', () {
      // Arrange
      const p0 = TrajectoryPoint(latitude: 0, longitude: 0);
      const p1 = TrajectoryPoint(latitude: 1, longitude: 0);
      const p2 = TrajectoryPoint(latitude: 2, longitude: 0);
      const p3 = TrajectoryPoint(latitude: 3, longitude: 0);

      // Act
      final result = CatmullRomInterpolator.interpolate(
        t: 0.5,
        p0: p0,
        p1: p1,
        p2: p2,
        p3: p3,
      );

      // Assert - 在p1和p2中间应该是1.5
      expect(result.latitude, closeTo(1.5, 0.001));
    });

    test('should handle angle interpolation correctly', () {
      // Arrange
      const p0 = TrajectoryPoint(latitude: 0, longitude: 0, heading: 350);
      const p1 = TrajectoryPoint(latitude: 1, longitude: 0, heading: 10);
      const p2 = TrajectoryPoint(latitude: 2, longitude: 0, heading: 20);
      const p3 = TrajectoryPoint(latitude: 3, longitude: 0, heading: 30);

      // Act
      final result = CatmullRomInterpolator.interpolate(
        t: 0.5,
        p0: p0,
        p1: p1,
        p2: p2,
        p3: p3,
      );

      // Assert - 角度应该正确处理360°循环
      expect(result.heading, isNotNull);
      expect(result.heading!, greaterThanOrEqualTo(0));
      expect(result.heading!, lessThan(360));
    });

    test('should interpolate entire path', () {
      // Act
      final interpolated = CatmullRomInterpolator.interpolatePath(
        points: testPoints,
        segmentsPerInterval: 3,
      );

      // Assert
      expect(interpolated.length, greaterThan(testPoints.length));
      expect(interpolated.first.latitude, testPoints.first.latitude);
      expect(interpolated.last.latitude, testPoints.last.latitude);
    });

    test('should handle edge cases', () {
      // Test with insufficient points
      final insufficientPoints = [
        TrajectoryPoint(latitude: 0, longitude: 0),
        TrajectoryPoint(latitude: 1, longitude: 1),
      ];

      final result = CatmullRomInterpolator.interpolatePath(
        points: insufficientPoints,
        segmentsPerInterval: 3,
      );

      expect(result.length, 2);
    });
  });
}
