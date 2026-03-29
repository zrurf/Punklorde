import 'dart:async';

import 'package:dart_date/dart_date.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/module/feature/cqupt/sport/constant.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/service/motion_sim/bridge.dart';
import 'package:punklorde/src/rust/services/motion_sim/model.dart';
import 'package:punklorde/utils/lbs/distance.dart';
import 'package:signals/signals_flutter.dart';

class InnerSportServiceConfig {
  final SportMode mode;

  final String placeCode;
  final String placeName;

  final AutoRunningConfig? autoRunConfig;

  final Future<String?> Function() startCaallback;
  final Future<void> Function(String sportId) stopCallback;
  final void Function(String sportId, TrajPoint point) recordCallback;
  final Future<UploadCallbackRsult?> Function(
    String sportId,
    List<TrajPoint> points,
  )
  uploadCallback;
  final Future<void> Function(String sportId, List<TrajPoint> points)
  retryUploadCallback;

  const InnerSportServiceConfig({
    required this.mode,
    required this.placeCode,
    required this.placeName,
    this.autoRunConfig,
    required this.startCaallback,
    required this.stopCallback,
    required this.recordCallback,
    required this.uploadCallback,
    required this.retryUploadCallback,
  });
}

class InnerSportService {
  // 配置
  InnerSportServiceConfig? _config;

  MotionSimulatorController? _simController; // 运动模拟器
  Stream<SimulatorUpdate>? _simStream; // 运动模拟器数据流

  // 状态
  bool isRunning = false; // 服务是否正在运行
  bool _isUploading = false; // 是否正在上传
  bool _isNeedUpload = false; // 是否需要上传
  String? _sportId; // 运动ID
  Computed<Coordinate> currentPoint = computed(
    () => Coordinate(lat: rawLat.value, lng: rawLng.value),
  ); // 当前位置
  Coordinate? _lastLocation; // 上一次位置
  DateTime? _lastUpdateTime; // 上一次位置更新时间
  EffectCleanup? _locationEffect; // 位置监听器
  SimulatorStats? _latestSimStats; // 运动模拟器状态

  // 封装状态
  double _speed = 0; // 当前速度
  double _distance = 0; // 当前距离
  int _elapsedTime = 0; // 运动时间（毫秒）

  // 上传缓冲区
  final List<TrajPoint> _uploadBuffer = [];
  final List<TrajPoint> _retryBuffer = [];

  // 记录区
  final List<TrajPoint> _recordBuffer = [];

  // 访问器
  List<TrajPoint> get recordPoints => _recordBuffer;
  double get getSpeed => _speed;
  double get getDistance => _distance;
  int get getElapsedTime => _elapsedTime;

  // 开始运行
  Future<bool> start(InnerSportServiceConfig config) async {
    _config = config;
    isRunning = true;

    _lastLocation = null;
    _distance = 0;
    _elapsedTime = 0;
    _speed = 0;

    // 初始化
    switch (config.mode) {
      case SportMode.auto:
        if (config.autoRunConfig == null) {
          return false;
        }
        await _simulatorInit(
          config.autoRunConfig!.simulatorConfig,
          config.autoRunConfig!.trajectories,
          config.autoRunConfig!.updateFrequency,
        );
        _isNeedUpload = true;
        break;
      case SportMode.normal:
        _isNeedUpload = true;
        break;
      case SportMode.record:
        _isNeedUpload = false;
        _recordBuffer.clear();
        break;
    }

    // 开始
    _sportId = await config.startCaallback();

    if (_sportId == null) {
      _stop(.error);
      return false;
    }

    // 启动
    switch (config.mode) {
      case SportMode.auto:
        _simulatorStart(config.autoRunConfig?.updateFrequency ?? 1000);
        break;
      case SportMode.normal:
        _distance = 0;
        _elapsedTime = 0;
        _locationEffect = effect(() {
          final now = DateTime.now();
          _handleNormalUpdate(currentPoint.value, now);
          _recordPoint(TrajPoint(coordinate: currentPoint.value, time: now));
        });
        break;
      case SportMode.record:
        _locationEffect = effect(() {
          final now = DateTime.now();
          _handleNormalUpdate(currentPoint.value, now);
          _recordBuffer.add(
            TrajPoint(coordinate: currentPoint.value, time: DateTime.now()),
          );
          config.recordCallback(
            _sportId!,
            TrajPoint(coordinate: currentPoint.value, time: now),
          );
        });
        break;
    }
    return true;
  }

  // 停止运行接口
  Future<void> stop() async {
    await _stop(.userRequested);
  }

  // 停止运行
  Future<void> _stop(StopReason reason) async {
    if (_locationEffect != null) _locationEffect!();
    _simController?.stopDriving();
    _simController?.stop(reason);
    if (_sportId != null) {
      await _config?.stopCallback(_sportId!);
      if (_retryBuffer.isNotEmpty) {
        await _config?.retryUploadCallback(_sportId!, _retryBuffer);
      }
    }
    _simStream = null;
    _simController?.dispose();
    _simController = null;
    _locationEffect = null;
    _config = null;
    _sportId = null;
    _latestSimStats = null;
    _uploadBuffer.clear();
    _retryBuffer.clear();
    isRunning = false;
  }

  // 运动模拟器初始化
  Future<void> _simulatorInit(
    SimulatorConfig config,
    List<Trajectory> trajectories,
    int frenquency,
  ) async {
    _simController = MotionSimulatorController();
    _simStream = await _simController?.initialize(config, trajectories);

    _simStream?.listen((update) {
      if (update is SimulatorUpdate_Event) {
        _handleEvent(update.field0);
      } else if (update is SimulatorUpdate_SensorData) {
        _handleSensorData(update.field0);
      }
    });
  }

  // 处理正常运动状态更新
  void _handleNormalUpdate(Coordinate currentPos, DateTime now) {
    if (_lastLocation != null && _lastUpdateTime != null) {
      final dDistance = haversineDistance(
        currentPos.lat,
        currentPos.lng,
        _lastLocation!.lat,
        _lastLocation!.lng,
      );
      final dTime = now.differenceInMilliseconds(_lastUpdateTime!);
      _distance += dDistance;
      _elapsedTime += dTime;
      _speed = (dTime > 0 && dDistance > 0) ? dDistance / (dTime / 1000.0) : 0;
      _lastLocation = currentPos;
      _lastUpdateTime = now;
    } else {
      _lastLocation = currentPos;
      _lastUpdateTime = now;
    }
  }

  // 处理运动模拟器事件
  void _handleEvent(SimulatorEvent event) {
    _latestSimStats = _simController?.getSimulatorStats();
    if (_latestSimStats != null) {
      _distance = _latestSimStats!.totalDistance;
      _elapsedTime = _latestSimStats!.elapsedTimeMs.toInt();
    }
  }

  // 处理传感器数据
  void _handleSensorData(SensorData sensorData) {
    if (sensorData.gps != null) {
      _speed = sensorData.gps!.speed;
      final point = sensorData.gps!.position;
      _recordPoint(
        TrajPoint(
          coordinate: .new(lat: point.latitude, lng: point.longitude),
          time: DateTime.now(),
        ),
      );
    }
  }

  // 运动模拟器开始
  void _simulatorStart(int interval) {
    _simController?.start();
    _simController?.startDrivingWithFixedRate(
      interval: Duration(milliseconds: interval),
    );
  }

  // 添加点
  Future<void> _recordPoint(TrajPoint point) async {
    _uploadBuffer.add(point);
    _config?.recordCallback(_sportId!, point);
    await _tryUpload();
  }

  // 检查并触发上传
  Future<void> _tryUpload() async {
    if (!_isNeedUpload) return;
    if (_isUploading) return; // 正在上传，避免并发
    if (_uploadBuffer.length < uploadThreshold) return; // 点数不足
    _isUploading = true;
    await _upload(_uploadBuffer);
    final last = _uploadBuffer.last;
    _uploadBuffer.clear();
    _uploadBuffer.add(last);
  }

  // 上传
  Future<void> _upload(List<TrajPoint> points) async {
    try {
      UploadCallbackRsult? result = await _config?.uploadCallback(
        _sportId!,
        points,
      );
      if (result == null) {
        throw Exception('upload callback return null');
      }
    } catch (e) {
      _retryBuffer.addAll(points);
    } finally {
      _isUploading = false;
    }
  }
}
