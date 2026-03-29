import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:punklorde/src/rust/api/motion_sim.dart';
import 'package:punklorde/src/rust/services/motion_sim/model.dart';

class MotionSimulatorController {
  String? _handleId;
  StreamSubscription<SimulatorUpdate>? _subscription;
  final StreamController<SimulatorUpdate> _updateController =
      StreamController.broadcast();
  Stream<SimulatorUpdate> get updates => _updateController.stream;

  bool _isDriving = false;
  Timer? _timer;
  Stopwatch? _stopwatch;
  Duration _lastFrameTime = Duration.zero;

  /// 初始化模拟器，返回数据流
  Future<Stream<SimulatorUpdate>> initialize(
    SimulatorConfig config,
    List<Trajectory> trajectories,
  ) async {
    // 1. 创建模拟器，获得句柄 ID
    final handleId = createSimulator(
      config: config,
      trajectories: trajectories,
    );
    _handleId = handleId;

    // 2. 订阅数据流（subscribeSimulator 返回 Future<Stream<SimulatorUpdate>>）
    final stream = await subscribeSimulator(handleId: handleId);
    _subscription = stream.listen(
      (update) => _updateController.add(update),
      onError: (error) => _updateController.addError(error),
    );

    return _updateController.stream; // 也可直接返回 stream
  }

  // ---------- 控制方法 ----------
  void start() {
    if (_handleId != null) startSimulator(handleId: _handleId!);
  }

  void pause() {
    if (_handleId != null) pauseSimulator(handleId: _handleId!);
  }

  void resume() {
    if (_handleId != null) resumeSimulator(handleId: _handleId!);
  }

  void stop(StopReason reason) {
    if (_handleId != null) stopSimulator(handleId: _handleId!, reason: reason);
  }

  CommandResult execSimulatorCommand(Command command) {
    if (_handleId == null) throw StateError('Simulator not initialized');
    return executeCommand(handleId: _handleId!, command: command);
  }

  SimulatorStats? getSimulatorStats() {
    if (_handleId == null) throw StateError('Simulator not initialized');
    return getStats(handleId: _handleId!);
  }

  SimulatorState? getSimulatorState() {
    if (_handleId == null) throw StateError('Simulator not initialized');
    return getState(handleId: _handleId!);
  }

  SimulatorConfig? getSimulatorConfig() {
    if (_handleId == null) throw StateError('Simulator not initialized');
    return getConfig(handleId: _handleId!);
  }

  // ---------- 帧驱动 ----------
  void startDriving() {
    if (_isDriving) return;
    _isDriving = true;
    _lastFrameTime = Duration.zero;
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback);
  }

  void startDrivingWithFixedRate({
    Duration interval = const Duration(milliseconds: 100),
  }) {
    if (_isDriving) return;
    _isDriving = true;

    _stopwatch = Stopwatch()..start();
    _lastFrameTime = _stopwatch!.elapsed;

    _timer = Timer.periodic(interval, (timer) {
      if (!_isDriving) return;
      final now = _stopwatch!.elapsed;
      if (_lastFrameTime != Duration.zero) {
        final dt = (now - _lastFrameTime).inMicroseconds / 1e6;
        _update(dt);
      }
      _lastFrameTime = now;
    });
  }

  void stopDriving() {
    _isDriving = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch = null;
    _lastFrameTime = Duration.zero;
  }

  void _frameCallback(Duration timestamp) {
    if (!_isDriving) return;
    final now = timestamp;
    if (_lastFrameTime != Duration.zero) {
      final dt = (now - _lastFrameTime).inMicroseconds / 1e6;
      _update(dt);
    }
    _lastFrameTime = now;
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback);
  }

  void _update(double dt) {
    if (_handleId == null || !_isDriving) return;
    // 避免 dt 为 0 或负数
    if (dt <= 0.0) return;
    updateSimulator(handleId: _handleId!, dt: dt);
  }

  // ---------- 资源释放 ----------
  void dispose() {
    stopDriving();
    _subscription?.cancel();
    if (_handleId != null) {
      disposeSimulator(handleId: _handleId!);
    }
    _updateController.close();
  }
}
