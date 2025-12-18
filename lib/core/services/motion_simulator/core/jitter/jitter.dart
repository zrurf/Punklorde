class JitterConfig {
  /// 坐标抖动强度（米）
  final double positionJitterStrength;

  /// 速度抖动强度（米/秒）
  final double speedJitterStrength;

  /// 抖动频率（Hz）
  final double jitterFrequency;

  /// 噪声种子
  final int? seed;

  const JitterConfig({
    this.positionJitterStrength = 0.5,
    this.speedJitterStrength = 0.1,
    this.jitterFrequency = 1.0,
    this.seed,
  });
}

// lib/models/speed_model.dart
class SpeedModel {
  /// 基础配速（米/秒）
  final double basePace;

  /// 当前实际速度（考虑抖动和Tag影响）
  double currentSpeed;

  /// 速度乘数（用于Tag影响）
  double speedMultiplier;

  /// 是否在减速区域
  bool inSlowZone;

  SpeedModel({required this.basePace})
    : currentSpeed = basePace,
      speedMultiplier = 1.0,
      inSlowZone = false;

  /// 应用速度乘数
  void applySpeedMultiplier(double multiplier) {
    speedMultiplier = multiplier;
    _updateCurrentSpeed();
  }

  /// 应用速度抖动
  void applyJitter(double jitterValue) {
    // jitterValue范围[-1, 1]
    final jitterEffect = jitterValue * basePace * 0.1; // 抖动幅度为基础速度的10%
    currentSpeed = basePace * speedMultiplier + jitterEffect;
    // 确保速度不为负且不超过最大限制
    currentSpeed = currentSpeed.clamp(0.1, basePace * 2);
  }

  void _updateCurrentSpeed() {
    currentSpeed = basePace * speedMultiplier;
  }

  /// 重置到基础速度
  void reset() {
    speedMultiplier = 1.0;
    inSlowZone = false;
    _updateCurrentSpeed();
  }
}
