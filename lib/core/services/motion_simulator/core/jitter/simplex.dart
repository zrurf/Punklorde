import 'dart:math';

/// 简化的噪声生成器（模拟Simplex噪声）
/// 在实际项目中，可以替换为真正的Simplex噪声实现
class NoiseGenerator {
  static const _gradients3d = [
    [1, 1, 0],
    [-1, 1, 0],
    [1, -1, 0],
    [-1, -1, 0],
    [1, 0, 1],
    [-1, 0, 1],
    [1, 0, -1],
    [-1, 0, -1],
    [0, 1, 1],
    [0, -1, 1],
    [0, 1, -1],
    [0, -1, -1],
  ];

  final List<int> _permutation = List.filled(512, 0);
  final Random _random;

  NoiseGenerator({int? seed})
    : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    _initializePermutation();
  }

  void _initializePermutation() {
    final p = List<int>.generate(256, (i) => i);
    p.shuffle(_random);

    for (int i = 0; i < 256; i++) {
      _permutation[i] = p[i];
      _permutation[i + 256] = p[i];
    }
  }

  double _dot(List<int> g, double x, double y, double z) {
    return g[0] * x + g[1] * y + g[2] * z;
  }

  double _mix(double a, double b, double t) {
    return (1 - t) * a + t * b;
  }

  double _fade(double t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  /// 生成3D噪声值，范围[-1, 1]
  double noise3D(double x, double y, double z) {
    final X = x.floor() & 255;
    final Y = y.floor() & 255;
    final Z = z.floor() & 255;

    x -= x.floor();
    y -= y.floor();
    z -= z.floor();

    final u = _fade(x);
    final v = _fade(y);
    final w = _fade(z);

    final A = _permutation[X] + Y;
    final AA = _permutation[A] + Z;
    final AB = _permutation[A + 1] + Z;
    final B = _permutation[X + 1] + Y;
    final BA = _permutation[B] + Z;
    final BB = _permutation[B + 1] + Z;

    final gradAA = _gradients3d[_permutation[AA] % 12];
    final gradAB = _gradients3d[_permutation[AB] % 12];
    final gradBA = _gradients3d[_permutation[BA] % 12];
    final gradBB = _gradients3d[_permutation[BB] % 12];
    final gradAA1 = _gradients3d[_permutation[AA + 1] % 12];
    final gradAB1 = _gradients3d[_permutation[AB + 1] % 12];
    final gradBA1 = _gradients3d[_permutation[BA + 1] % 12];
    final gradBB1 = _gradients3d[_permutation[BB + 1] % 12];

    final lerp1 = _mix(_dot(gradAA, x, y, z), _dot(gradBA, x - 1, y, z), u);
    final lerp2 = _mix(
      _dot(gradAB, x, y - 1, z),
      _dot(gradBB, x - 1, y - 1, z),
      u,
    );
    final lerp3 = _mix(
      _dot(gradAA1, x, y, z - 1),
      _dot(gradBA1, x - 1, y, z - 1),
      u,
    );
    final lerp4 = _mix(
      _dot(gradAB1, x, y - 1, z - 1),
      _dot(gradBB1, x - 1, y - 1, z - 1),
      u,
    );

    final lerp5 = _mix(lerp1, lerp2, v);
    final lerp6 = _mix(lerp3, lerp4, v);

    return _mix(lerp5, lerp6, w);
  }

  /// 生成2D噪声值，范围[-1, 1]
  double noise2D(double x, double y) {
    return noise3D(x, y, 0);
  }
}
