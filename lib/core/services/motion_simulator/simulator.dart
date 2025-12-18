import 'dart:async';
import 'dart:math';
import 'package:signals/signals.dart';
import './model.dart';
import './core/interpolation/interpolation.dart';
import 'core/jitter/simplex.dart';
import './core/jitter/jitter.dart';
import './core/fence.dart';

/// 运动模拟输出数据
class MotionOutput {
  final TrajectoryPoint position;
  final double speed;
  final double? heading;
  final double? altitude;
  final DateTime timestamp;
  final Map<String, dynamic> extras;

  const MotionOutput({
    required this.position,
    required this.speed,
    this.heading,
    this.altitude,
    required this.timestamp,
    this.extras = const {},
  });
}

/// 运动模拟服务
class MotionSimulationService {
  // Signals信号（用于状态管理）
  final currentPosition = signal<TrajectoryPoint?>(null);
  final currentOutput = signal<MotionOutput?>(null);
  final isRunning = signal<bool>(false);
  final progress = signal<double>(0.0); // 0-1的进度
  final currentSpeed = signal<double>(0.0);
  final totalDistance = signal<double>(0.0);

  // 私有属性
  final _noiseGenerator = NoiseGenerator();
  Timer? _simulationTimer;
  DateTime? _simulationStartTime;
  double _elapsedDistance = 0.0;
  List<TrajectoryPoint> _interpolatedPath = [];
  int _currentPathIndex = 0;
  SpeedModel? _speedModel;
  GeoFence? _geoFence;

  // 配置
  late double _targetDistance;
  late double _refreshRate;
  late JitterConfig _jitterConfig;
  late MotionProfile _motionProfile;

  // Tag处理相关
  final Map<int, TagInfo> _activePointTags = {};
  final Map<String, AreaTagInfo> _activeAreaTags = {};

  // 性能优化：预计算的路径段
  final Map<String, List<TrajectoryPoint>> _precomputedPaths = {};

  /// 启动运动模拟
  Future<void> startSimulation({
    required MotionProfile motionProfile,
    required double pace, // 米/秒
    required double refreshRate, // Hz
    required double targetDistance, // 米
    JitterConfig jitterConfig = const JitterConfig(),
    GeoFence? geoFence,
  }) async {
    // 停止任何正在运行的模拟
    await stopSimulation();

    // 保存配置
    _motionProfile = motionProfile;
    _targetDistance = targetDistance;
    _refreshRate = refreshRate;
    _jitterConfig = jitterConfig;
    _geoFence = geoFence;

    // 初始化速度模型
    _speedModel = SpeedModel(basePace: pace);

    // 准备路径
    await _preparePath();

    // 重置状态
    _elapsedDistance = 0.0;
    _currentPathIndex = 0;
    totalDistance.value = 0.0;
    progress.value = 0.0;

    // 设置初始位置
    if (_interpolatedPath.isNotEmpty) {
      currentPosition.value = _interpolatedPath.first;
    }

    // 开始模拟
    _simulationStartTime = DateTime.now();
    isRunning.value = true;

    // 启动定时器
    final interval = Duration(milliseconds: (1000 / refreshRate).round());
    _simulationTimer = Timer.periodic(interval, _updateSimulation);
  }

  /// 准备路径（包括插值和预计算）
  Future<void> _preparePath() async {
    _interpolatedPath.clear();
    _precomputedPaths.clear();

    // 根据播放顺序处理路径
    final List<VirtualPath> pathsToPlay;
    switch (_motionProfile.playbackOrder) {
      case PlaybackOrder.sequential:
        pathsToPlay = List.from(_motionProfile.virtualPaths);
        break;
      case PlaybackOrder.random:
        pathsToPlay = List.from(_motionProfile.virtualPaths)..shuffle();
        break;
    }

    // 处理播放模式
    if (_motionProfile.playbackMode == PlaybackMode.loop) {
      // 循环播放，计算需要重复多少次以达到目标距离
      double accumulatedDistance = 0.0;
      final List<VirtualPath> loopedPaths = [];

      while (accumulatedDistance < _targetDistance) {
        for (final path in pathsToPlay) {
          if (accumulatedDistance >= _targetDistance) break;

          loopedPaths.add(path);
          accumulatedDistance += path.length;
        }
      }

      pathsToPlay.clear();
      pathsToPlay.addAll(loopedPaths);
    }

    // 插值所有路径
    for (final path in pathsToPlay) {
      // 检查是否已预计算
      String pathKey = '${path.id}_${_refreshRate}';
      if (!_precomputedPaths.containsKey(pathKey)) {
        // 使用Catmull-Rom插值
        final interpolated = CatmullRomInterpolator.interpolatePath(
          points: path.points,
          segmentsPerInterval: _calculateSegmentsPerInterval(path),
        );
        _precomputedPaths[pathKey] = interpolated;
      }

      _interpolatedPath.addAll(_precomputedPaths[pathKey]!);
    }

    // 限制总距离不超过目标距离
    _limitPathToTargetDistance();

    // 初始化Tag处理
    _initializeTagHandling(pathsToPlay);
  }

  /// 计算每段需要的插值段数
  int _calculateSegmentsPerInterval(VirtualPath path) {
    // 根据刷新率和期望速度计算
    final expectedSegmentLength = _speedModel!.basePace / _refreshRate;
    final averageSegmentLength = path.length / max(1, path.points.length - 1);
    final segments = (averageSegmentLength / expectedSegmentLength).ceil();
    return segments.clamp(1, 100); // 限制范围以避免性能问题
  }

  /// 限制路径到目标距离
  void _limitPathToTargetDistance() {
    double accumulatedDistance = 0.0;
    int lastValidIndex = 0;

    for (int i = 1; i < _interpolatedPath.length; i++) {
      final segmentDistance = _interpolatedPath[i - 1].distanceTo(
        _interpolatedPath[i],
      );
      if (accumulatedDistance + segmentDistance <= _targetDistance) {
        accumulatedDistance += segmentDistance;
        lastValidIndex = i;
      } else {
        break;
      }
    }

    totalDistance.value = accumulatedDistance;

    // 截断路径
    if (lastValidIndex < _interpolatedPath.length - 1) {
      _interpolatedPath = _interpolatedPath.sublist(0, lastValidIndex + 1);
    }
  }

  /// 初始化Tag处理
  void _initializeTagHandling(List<VirtualPath> paths) {
    _activePointTags.clear();
    _activeAreaTags.clear();

    // 这里需要根据路径索引映射来设置Tag
    // 简化实现：只处理第一个路径的Tag
    if (paths.isNotEmpty) {
      final firstPath = paths.first;

      // 处理点Tag
      for (final pointTag in firstPath.pointTags) {
        if (pointTag.pointIndex < firstPath.points.length &&
            pointTag.tagInfoIndex < firstPath.tagInfoPool.length) {
          _activePointTags[pointTag.pointIndex] =
              firstPath.tagInfoPool[pointTag.tagInfoIndex];
        }
      }

      // 处理区域Tag
      for (final areaTag in firstPath.areaTags) {
        if (areaTag.startIndex < firstPath.points.length &&
            areaTag.endIndex < firstPath.points.length &&
            areaTag.tagInfoIndex < firstPath.tagInfoPool.length) {
          final tagInfo = firstPath.tagInfoPool[areaTag.tagInfoIndex];
          _activeAreaTags[tagInfo.id] = AreaTagInfo(
            startIndex: areaTag.startIndex,
            endIndex: areaTag.endIndex,
            tagInfo: tagInfo,
          );
        }
      }
    }
  }

  /// 更新模拟状态
  void _updateSimulation(Timer timer) {
    if (!isRunning.value || _currentPathIndex >= _interpolatedPath.length - 1) {
      _completeSimulation();
      return;
    }

    // 计算本次移动的距离
    final distancePerUpdate = _speedModel!.currentSpeed / _refreshRate;
    _elapsedDistance += distancePerUpdate;

    // 更新进度
    progress.value = (_elapsedDistance / _targetDistance).clamp(0.0, 1.0);

    // 处理Tag影响
    _handleTagEffects();

    // 应用抖动
    _applyJitter();

    // 计算新位置
    _currentPathIndex = _calculateCurrentPathIndex();

    // 获取插值位置
    final interpolatedPosition = _getInterpolatedPosition();

    // 应用电子围栏纠正
    final correctedPosition =
        _geoFence?.correctPoint(interpolatedPosition) ?? interpolatedPosition;

    // 更新状态
    currentPosition.value = correctedPosition;
    currentSpeed.value = _speedModel!.currentSpeed;

    // 创建输出
    final output = MotionOutput(
      position: correctedPosition,
      speed: _speedModel!.currentSpeed,
      heading: correctedPosition.heading,
      altitude: correctedPosition.altitude,
      timestamp: DateTime.now(),
      extras: {
        'distance': _elapsedDistance,
        'progress': progress.value,
        'path_index': _currentPathIndex,
      },
    );

    currentOutput.value = output;

    // 检查是否完成
    if (progress.value >= 1.0 || _elapsedDistance >= _targetDistance) {
      _completeSimulation();
    }
  }

  /// 计算当前路径索引
  int _calculateCurrentPathIndex() {
    double accumulatedDistance = 0.0;

    for (int i = 1; i < _interpolatedPath.length; i++) {
      final segmentDistance = _interpolatedPath[i - 1].distanceTo(
        _interpolatedPath[i],
      );
      accumulatedDistance += segmentDistance;

      if (accumulatedDistance >= _elapsedDistance) {
        // 找到对应的段，返回起始索引
        return i - 1;
      }
    }

    return _interpolatedPath.length - 1;
  }

  /// 获取插值位置
  TrajectoryPoint _getInterpolatedPosition() {
    if (_currentPathIndex >= _interpolatedPath.length - 1) {
      return _interpolatedPath.last;
    }

    // 计算在当前段内的比例
    final segmentStart = _interpolatedPath[_currentPathIndex];
    final segmentEnd = _interpolatedPath[_currentPathIndex + 1];

    // 计算已在本段移动的距离
    double distanceInSegment = 0.0;
    for (int i = 0; i <= _currentPathIndex; i++) {
      if (i < _interpolatedPath.length - 1) {
        distanceInSegment += _interpolatedPath[i].distanceTo(
          _interpolatedPath[i + 1],
        );
      }
    }

    final segmentDistance = segmentStart.distanceTo(segmentEnd);
    final segmentProgress =
        (_elapsedDistance - distanceInSegment) / segmentDistance;

    // 使用线性插值（性能更好，实际项目可根据需要改为Catmull-Rom）
    return TrajectoryPoint(
      latitude:
          segmentStart.latitude +
          (segmentEnd.latitude - segmentStart.latitude) * segmentProgress,
      longitude:
          segmentStart.longitude +
          (segmentEnd.longitude - segmentStart.longitude) * segmentProgress,
      altitude: segmentStart.altitude != null && segmentEnd.altitude != null
          ? segmentStart.altitude! +
                (segmentEnd.altitude! - segmentStart.altitude!) *
                    segmentProgress
          : null,
      heading: segmentStart.heading != null && segmentEnd.heading != null
          ? _interpolateAngle(
              segmentStart.heading!,
              segmentEnd.heading!,
              segmentProgress,
            )
          : null,
    );
  }

  /// 角度插值
  double _interpolateAngle(double start, double end, double progress) {
    double diff = end - start;

    // 处理角度跨越360°的情况
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    double result = start + diff * progress;

    // 规范化到0-360
    if (result >= 360) result -= 360;
    if (result < 0) result += 360;

    return result;
  }

  /// 处理Tag效果
  void _handleTagEffects() {
    // 检查点Tag
    if (_activePointTags.containsKey(_currentPathIndex)) {
      final tagInfo = _activePointTags[_currentPathIndex]!;

      // 检查点：临时减速
      if (tagInfo.id == 'checkpoint') {
        final slowdownRatio = tagInfo.ext['slowdown_ratio'] as double? ?? 0.5;
        final duration = tagInfo.ext['duration'] as double? ?? 2.0; // 秒

        _applyTemporarySlowdown(slowdownRatio, duration);
      }
    }

    // 检查区域Tag
    for (final areaTag in _activeAreaTags.values) {
      if (_currentPathIndex >= areaTag.startIndex &&
          _currentPathIndex <= areaTag.endIndex) {
        if (areaTag.tagInfo.id == 'check_area') {
          final targetSpeed = areaTag.tagInfo.ext['target_speed'] as double?;
          if (targetSpeed != null) {
            _speedModel!.inSlowZone = true;
            _speedModel!.applySpeedMultiplier(
              targetSpeed / _speedModel!.basePace,
            );
          }
        }
      } else if (_speedModel!.inSlowZone) {
        // 离开减速区域，恢复速度
        _speedModel!.reset();
      }
    }
  }

  /// 应用临时减速
  void _applyTemporarySlowdown(double ratio, double duration) {
    // 简化实现：立即应用减速，duration秒后恢复
    _speedModel!.applySpeedMultiplier(ratio);

    // 使用Timer恢复速度（实际项目需要更精细的控制）
    Timer(Duration(seconds: duration.toInt()), () {
      if (isRunning.value) {
        _speedModel!.reset();
      }
    });
  }

  /// 应用抖动
  void _applyJitter() {
    if (_jitterConfig.positionJitterStrength > 0) {
      // 使用噪声生成抖动值
      final noise = _noiseGenerator.noise3D(
        _elapsedDistance * _jitterConfig.jitterFrequency,
        0,
        0,
      );

      // 应用速度抖动
      _speedModel!.applyJitter(noise);
    }
  }

  /// 完成模拟
  void _completeSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    isRunning.value = false;
    progress.value = 1.0;

    // 发送完成事件
    // 实际项目中可以添加事件系统
  }

  /// 停止模拟
  Future<void> stopSimulation() async {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    isRunning.value = false;

    // 重置速度模型
    _speedModel?.reset();
  }

  /// 暂停模拟
  void pauseSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    isRunning.value = false;
  }

  /// 恢复模拟
  void resumeSimulation() {
    if (!isRunning.value && _simulationStartTime != null) {
      isRunning.value = true;
      final interval = Duration(milliseconds: (1000 / _refreshRate).round());
      _simulationTimer = Timer.periodic(interval, _updateSimulation);
    }
  }

  /// 清理资源
  void dispose() {
    stopSimulation();
    currentPosition.dispose();
    currentOutput.dispose();
    isRunning.dispose();
    progress.dispose();
    currentSpeed.dispose();
    totalDistance.dispose();
  }
}

/// 区域Tag信息（辅助类）
class AreaTagInfo {
  final int startIndex;
  final int endIndex;
  final TagInfo tagInfo;

  const AreaTagInfo({
    required this.startIndex,
    required this.endIndex,
    required this.tagInfo,
  });
}
