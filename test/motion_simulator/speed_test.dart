// test/models/speed_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:punklorde/core/services/motion_simulator/core/jitter/jitter.dart';

void main() {
  group('SpeedModel', () {
    const basePace = 5.0; // 5 m/s

    test('should initialize with base pace', () {
      // Arrange & Act
      final model = SpeedModel(basePace: basePace);

      // Assert
      expect(model.basePace, basePace);
      expect(model.currentSpeed, basePace);
      expect(model.speedMultiplier, 1.0);
      expect(model.inSlowZone, false);
    });

    test('should apply speed multiplier', () {
      // Arrange
      final model = SpeedModel(basePace: basePace);
      const multiplier = 0.5;

      // Act
      model.applySpeedMultiplier(multiplier);

      // Assert
      expect(model.speedMultiplier, multiplier);
      expect(model.currentSpeed, basePace * multiplier);
    });

    test('should apply jitter within limits', () {
      // Arrange
      final model = SpeedModel(basePace: basePace);
      const jitterValue = 0.5; // Range [-1, 1]

      // Act
      model.applyJitter(jitterValue);

      // Assert
      expect(model.currentSpeed, greaterThan(0));
      expect(model.currentSpeed, lessThanOrEqualTo(basePace * 2));

      // 验证抖动效果
      const expectedJitterEffect = jitterValue * basePace * 0.1;
      expect(
        model.currentSpeed,
        closeTo(basePace + expectedJitterEffect, 0.001),
      );
    });

    test('should clamp jitter to minimum speed', () {
      // Arrange
      final model = SpeedModel(basePace: basePace);
      const largeNegativeJitter = -10.0; // 会导致速度变为负值

      // Act
      model.applyJitter(largeNegativeJitter);

      // Assert - 速度应该被限制在最小值
      expect(model.currentSpeed, greaterThan(0));
    });

    test('should reset to base speed', () {
      // Arrange
      final model = SpeedModel(basePace: basePace);
      model.applySpeedMultiplier(0.5);
      model.inSlowZone = true;

      // Act
      model.reset();

      // Assert
      expect(model.speedMultiplier, 1.0);
      expect(model.currentSpeed, basePace);
      expect(model.inSlowZone, false);
    });
  });
}
