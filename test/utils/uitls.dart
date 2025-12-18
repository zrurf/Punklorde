import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// 测试环境配置
class TestConfig {
  static const defaultTimeout = Duration(seconds: 10);
  static const fastTimeout = Duration(milliseconds: 500);
}

/// 模拟时钟，用于控制时间
class MockClock {
  DateTime _currentTime = DateTime.now();

  void setTime(DateTime time) {
    _currentTime = time;
  }

  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  DateTime get now => _currentTime;
}

/// 异步测试辅助工具
class AsyncTestHelper {
  /// 等待信号值更新
  static Future<void> waitForSignalUpdate<T>(
    T Function() getValue,
    T expectedValue, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 10),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      if (getValue() == expectedValue) {
        return;
      }
      await Future.delayed(interval);
    }

    throw TimeoutException('等待信号更新超时，期望值: $expectedValue, 实际值: ${getValue()}');
  }

  /// 等待条件成立
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 10),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      if (condition()) {
        return;
      }
      await Future.delayed(interval);
    }

    throw TimeoutException('等待条件成立超时');
  }
}
