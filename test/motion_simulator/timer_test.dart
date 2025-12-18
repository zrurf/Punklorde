import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:punklorde/core/services/motion_simulator/simulator.dart';
import 'package:punklorde/core/services/motion_simulator/model.dart';
import 'package:punklorde/core/services/motion_simulator/core/jitter/jitter.dart';

void main() {
  group('MotionSimulationService Timer Tests', () {
    test('should respect refresh rate with fake async', () {
      fakeAsync((async) {
        // Arrange
        final service = MotionSimulationService();

        final testProfile = MotionProfile(
          id: 'test',
          name: 'Test',
          virtualPaths: [
            VirtualPath(
              id: 'path',
              name: 'Path',
              points: [
                TrajectoryPoint(latitude: 0, longitude: 0),
                TrajectoryPoint(latitude: 0.001, longitude: 0),
              ],
              length: 111.0,
            ),
          ],
        );

        int positionUpdates = 0;
        service.currentPosition.subscribe((v) {
          positionUpdates++;
        });

        // Act - 启动模拟，刷新率10Hz（每100ms更新一次）
        service.startSimulation(
          motionProfile: testProfile,
          pace: 10.0,
          refreshRate: 10.0,
          targetDistance: 50.0,
          jitterConfig: const JitterConfig(),
        );

        // 前进时间
        async.elapse(const Duration(milliseconds: 100));

        // Assert - 应该有一次位置更新
        expect(positionUpdates, 1);

        // 再前进100ms
        async.elapse(const Duration(milliseconds: 100));
        expect(positionUpdates, 2);

        // 停止模拟
        service.stopSimulation();
        service.dispose();
      });
    });

    test('should complete simulation after elapsed time', () {
      fakeAsync((async) {
        // Arrange
        final service = MotionSimulationService();

        final testProfile = MotionProfile(
          id: 'test',
          name: 'Test',
          virtualPaths: [
            VirtualPath(
              id: 'path',
              name: 'Path',
              points: [
                TrajectoryPoint(latitude: 0, longitude: 0),
                TrajectoryPoint(latitude: 0.01, longitude: 0), // 约1110米
              ],
              length: 1110.0,
            ),
          ],
        );

        // 目标距离100米，速度10m/s，应该需要10秒
        service.startSimulation(
          motionProfile: testProfile,
          pace: 10.0,
          refreshRate: 10.0,
          targetDistance: 100.0,
          jitterConfig: const JitterConfig(),
        );

        // 前进9秒
        async.elapse(const Duration(seconds: 9));
        expect(service.isRunning.value, true);
        expect(service.progress.value, lessThan(1.0));

        // 再前进2秒（总共11秒）
        async.elapse(const Duration(seconds: 2));

        // Assert - 模拟应该已完成
        expect(service.isRunning.value, false);
        expect(service.progress.value, 1.0);

        service.dispose();
      });
    });

    test('should handle multiple rapid timer events', () {
      fakeAsync((async) {
        // Arrange
        final service = MotionSimulationService();

        final testProfile = MotionProfile(
          id: 'test',
          name: 'Test',
          virtualPaths: [
            VirtualPath(
              id: 'path',
              name: 'Path',
              points: List.generate(
                100,
                (i) => TrajectoryPoint(latitude: i * 0.0001, longitude: 0),
              ),
              length: 1100.0,
            ),
          ],
        );

        final positions = <TrajectoryPoint>[];
        service.currentPosition.subscribe((v) {
          if (v != null) {
            positions.add(v);
          }
        });

        // Act - 启动高刷新率模拟
        service.startSimulation(
          motionProfile: testProfile,
          pace: 100.0, // 高速
          refreshRate: 100.0, // 100Hz，每10ms更新
          targetDistance: 500.0,
          jitterConfig: const JitterConfig(),
        );

        // 快速前进时间，模拟密集的定时器事件
        for (int i = 0; i < 50; i++) {
          async.elapse(const Duration(milliseconds: 10));
        }

        // Assert
        expect(positions.length, greaterThan(10));

        // 验证位置是递增的（纬度增加）
        for (int i = 1; i < positions.length; i++) {
          expect(
            positions[i].latitude,
            greaterThanOrEqualTo(positions[i - 1].latitude),
          );
        }

        service.stopSimulation();
        service.dispose();
      });
    });
  });
}
