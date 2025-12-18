import 'package:flutter_test/flutter_test.dart';
import 'package:punklorde/core/services/motion_simulator/core/jitter/simplex.dart';

void main() {
  group('NoiseGenerator', () {
    test('should generate consistent noise with same seed', () {
      // Arrange
      final generator1 = NoiseGenerator(seed: 12345);
      final generator2 = NoiseGenerator(seed: 12345);

      const x = 1.0;
      const y = 2.0;
      const z = 3.0;

      // Act
      final noise1 = generator1.noise3D(x, y, z);
      final noise2 = generator2.noise3D(x, y, z);

      // Assert
      expect(noise1, equals(noise2));
    });

    test('should generate different noise with different seeds', () {
      // Arrange
      final generator1 = NoiseGenerator(seed: 12345);
      final generator2 = NoiseGenerator(seed: 67890);

      const x = 1.0;
      const y = 2.0;
      const z = 3.0;

      // Act
      final noise1 = generator1.noise3D(x, y, z);
      final noise2 = generator2.noise3D(x, y, z);

      // Assert
      expect(noise1, isNot(equals(noise2)));
    });

    test('should generate noise in expected range', () {
      // Arrange
      final generator = NoiseGenerator();
      const testPoints = 100;

      // Act & Assert
      for (int i = 0; i < testPoints; i++) {
        final noise = generator.noise3D(i * 0.1, i * 0.2, i * 0.3);

        expect(noise, greaterThanOrEqualTo(-1.0));
        expect(noise, lessThanOrEqualTo(1.0));
      }
    });

    test('should generate smooth noise for close points', () {
      // Arrange
      final generator = NoiseGenerator(seed: 42);
      const epsilon = 0.01;

      // Act
      final noise1 = generator.noise3D(1.0, 2.0, 3.0);
      final noise2 = generator.noise3D(1.0 + epsilon, 2.0, 3.0);

      // Assert - 相邻点的噪声值应该相近
      expect((noise1 - noise2).abs(), lessThan(0.1));
    });

    test('2D noise should be consistent with 3D noise', () {
      // Arrange
      final generator = NoiseGenerator(seed: 99);
      const x = 5.0;
      const y = 10.0;

      // Act
      final noise2D = generator.noise2D(x, y);
      final noise3D = generator.noise3D(x, y, 0);

      // Assert
      expect(noise2D, equals(noise3D));
    });
  });
}
