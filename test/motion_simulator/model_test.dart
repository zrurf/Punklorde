import 'package:flutter_test/flutter_test.dart';
import 'package:punklorde/core/services/motion_simulator/model.dart';

void main() {
  group('TrajectoryPoint', () {
    test('should create point with valid coordinates', () {
      // Arrange & Act
      const point = TrajectoryPoint(
        latitude: 31.2304,
        longitude: 121.4737,
        altitude: 10.0,
        heading: 45.0,
      );

      // Assert
      expect(point.latitude, 31.2304);
      expect(point.longitude, 121.4737);
      expect(point.altitude, 10.0);
      expect(point.heading, 45.0);
    });

    test('should calculate distance between two points', () {
      // Arrange
      const point1 = TrajectoryPoint(latitude: 31.2304, longitude: 121.4737);

      const point2 = TrajectoryPoint(
        latitude: 31.2314, // 大约111米北移
        longitude: 121.4737,
      );

      // Act
      final distance = point1.distanceTo(point2);

      // Assert
      expect(distance, greaterThan(100)); // 大约111米
      expect(distance, lessThan(120));
    });

    test('should serialize and deserialize correctly', () {
      // Arrange
      const originalPoint = TrajectoryPoint(
        latitude: 31.2304,
        longitude: 121.4737,
        altitude: 10.0,
        heading: 45.0,
      );

      // Act
      final json = originalPoint.toJson();
      final deserializedPoint = TrajectoryPoint.fromJson(json);

      // Assert
      expect(deserializedPoint.latitude, originalPoint.latitude);
      expect(deserializedPoint.longitude, originalPoint.longitude);
      expect(deserializedPoint.altitude, originalPoint.altitude);
      expect(deserializedPoint.heading, originalPoint.heading);
    });
  });
}
