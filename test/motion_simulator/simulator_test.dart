import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:punklorde/core/services/motion_simulator/model.dart';
import 'package:punklorde/core/services/motion_simulator/simulator.dart';
import 'package:punklorde/core/services/motion_simulator/core/jitter/jitter.dart';
import '../utils/uitls.dart';

void main() {
  group('MotionSimulationService Integration Tests', () {
    late MotionSimulationService service;
    late MotionProfile testProfile;

    setUp(() {
      service = MotionSimulationService();

      // 创建测试运动配置
      testProfile = MotionProfile(
        id: 'test_profile',
        name: 'Test Profile',
        virtualPaths: [
          VirtualPath(
            id: 'test_path',
            name: 'Test Path',
            points: [
              TrajectoryPoint(latitude: 0, longitude: 0),
              TrajectoryPoint(latitude: 0.001, longitude: 0), // 约111米
              TrajectoryPoint(latitude: 0.002, longitude: 0), // 约222米
            ],
            length: 222.0,
            tagInfoPool: [
              TagInfo(
                id: 'checkpoint',
                ext: {'slowdown_ratio': 0.5, 'duration': 1.0},
              ),
            ],
            pointTags: [PointTag(pointIndex: 1, tagInfoIndex: 0)],
          ),
        ],
        playbackMode: PlaybackMode.once,
        playbackOrder: PlaybackOrder.sequential,
      );
    });

    tearDown(() async {
      await service.stopSimulation();
      service.dispose();
    });

    test('should start and stop simulation', () async {
      // Arrange
      expect(service.isRunning.value, false);

      // Act
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 5.0,
        refreshRate: 10.0,
        targetDistance: 100.0,
        jitterConfig: const JitterConfig(),
      );

      // Assert
      expect(service.isRunning.value, true);

      // Act - 停止模拟
      await service.stopSimulation();

      // Assert
      await AsyncTestHelper.waitForCondition(
        () => !service.isRunning.value,
        timeout: const Duration(milliseconds: 500),
      );
    });

    test('should update position during simulation', () async {
      // Arrange
      TrajectoryPoint? lastPosition;
      service.currentPosition.subscribe((v) {
        lastPosition = v;
      });

      // Act
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 10.0, // 快速移动以便测试
        refreshRate: 10.0,
        targetDistance: 50.0,
        jitterConfig: const JitterConfig(),
      );

      // Assert
      await AsyncTestHelper.waitForCondition(
        () => lastPosition != null,
        timeout: const Duration(seconds: 2),
      );

      expect(lastPosition, isNotNull);
      expect(lastPosition!.latitude, isNotNull);
      expect(lastPosition!.longitude, isNotNull);
    });

    test('should update progress during simulation', () async {
      // Arrange
      double? lastProgress;
      service.progress.subscribe((v) {
        lastProgress = v;
      });

      // Act
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 10.0,
        refreshRate: 10.0,
        targetDistance: 50.0,
        jitterConfig: const JitterConfig(),
      );

      // 等待进度更新
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      expect(lastProgress, isNotNull);
      expect(lastProgress!, greaterThan(0));
      expect(lastProgress!, lessThanOrEqualTo(1.0));
    });

    test('should complete simulation when target distance reached', () async {
      // Arrange
      bool simulationCompleted = false;
      service.progress.subscribe((v) {
        if (v >= 1.0) {
          simulationCompleted = true;
        }
      });

      // Act - 使用较快的速度
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 50.0, // 快速完成
        refreshRate: 10.0,
        targetDistance: 100.0,
        jitterConfig: const JitterConfig(),
      );

      // 等待模拟完成
      await AsyncTestHelper.waitForCondition(
        () => simulationCompleted,
        timeout: const Duration(seconds: 3),
      );

      // Assert
      expect(simulationCompleted, true);
      expect(service.progress.value, 1.0);
      expect(service.isRunning.value, false);
    });

    test('should pause and resume simulation', () async {
      // Arrange
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 5.0,
        refreshRate: 10.0,
        targetDistance: 100.0,
        jitterConfig: const JitterConfig(),
      );

      // 等待模拟开始
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - 暂停
      service.pauseSimulation();

      // Assert
      expect(service.isRunning.value, false);

      // 记录当前位置
      final positionBeforePause = service.currentPosition.value;

      // 等待一小段时间，位置应该不变
      await Future.delayed(const Duration(milliseconds: 200));
      expect(service.currentPosition.value, positionBeforePause);

      // Act - 恢复
      service.resumeSimulation();

      // Assert
      expect(service.isRunning.value, true);

      // 等待位置更新
      await Future.delayed(const Duration(milliseconds: 200));
      expect(service.currentPosition.value, isNot(positionBeforePause));
    });

    test('should handle checkpoint tags', () async {
      // Arrange
      double? speedDuringCheckpoint;

      // 监听速度变化
      service.currentSpeed.subscribe((v) {
        if (v < 5.0) {
          speedDuringCheckpoint = v;
        }
      });

      // Act - 启动模拟，路径中包含检查点
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 5.0,
        refreshRate: 10.0,
        targetDistance: 150.0, // 确保经过检查点
        jitterConfig: const JitterConfig(),
      );

      // 等待经过检查点
      await AsyncTestHelper.waitForCondition(
        () => speedDuringCheckpoint != null,
        timeout: const Duration(seconds: 3),
      );

      // Assert - 检查点应该导致减速
      expect(speedDuringCheckpoint, isNotNull);
      expect(speedDuringCheckpoint!, lessThan(5.0));

      // 等待速度恢复
      await Future.delayed(const Duration(seconds: 2));
      expect(service.currentSpeed.value, closeTo(5.0, 1.0));
    });

    test('should apply jitter to movement', () async {
      // Arrange
      final speeds = <double>[];
      service.currentSpeed.subscribe((v) {
        speeds.add(v);
      });

      // Act
      await service.startSimulation(
        motionProfile: testProfile,
        pace: 5.0,
        refreshRate: 20.0, // 更高的刷新率以捕获更多速度变化
        targetDistance: 50.0,
        jitterConfig: const JitterConfig(speedJitterStrength: 0.5),
      );

      // 收集一些速度样本
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - 速度应该有变化（抖动）
      expect(speeds.length, greaterThan(1));

      // 计算速度变化
      bool hasVariation = false;
      for (int i = 1; i < speeds.length; i++) {
        if ((speeds[i] - speeds[i - 1]).abs() > 0.01) {
          hasVariation = true;
          break;
        }
      }

      expect(hasVariation, true);
    });
  });
}
