import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/models/auth.dart';
import 'package:punklorde/common/utils/lbs/distance.dart';
import 'package:punklorde/common/utils/permission/checker.dart';
import 'package:punklorde/common/models/location.dart';
import 'package:punklorde/core/services/lbs/location.dart';
import 'package:punklorde/core/services/motion_simulator/model.dart';
import 'package:punklorde/core/services/motion_simulator/simulator.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/api/api.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/const/const.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/data.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/model.dart'
    hide VirtualPath, MotionProfile;
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import './model.dart' as schema;

final _runConfig = signal<RunConfig>(RunConfig(distance: 2100));
final _runConfigNotifier = ValueNotifier<RunConfig>(_runConfig.value);

final class ModuleTontianView extends StatefulWidget {
  const ModuleTontianView({super.key});

  @override
  State<StatefulWidget> createState() => _ModuleTontianViewState();
}

class _ModuleTontianViewState extends State<ModuleTontianView>
    with TickerProviderStateMixin {
  final GlobalKey<_ModuleTontianViewState> widgetKey = GlobalKey();

  // 地图参数
  final BMFMapOptions _mapOption = BMFMapOptions(
    center: BMFCoordinate(39.965, 116.404),
    zoomLevel: 18,
    buildingsEnabled: true,
  );

  // 地图控制器
  BMFMapController? _mapController;

  // UI控制器
  late final FSelectController<MapItem> _selectCtrlMp;
  final _textCtrlSpeed = TextEditingController(text: "3.2");
  final _textCtrlInterval = TextEditingController(text: "1000");
  final _textCtrlDistance = TextEditingController(text: "2100");

  // UI动画控制器
  late final AnimationController _animeCtrl;
  late final Animation<double> _animation;

  // 运动模拟服务
  MotionSimulationService? _motionSimService;

  // 运动配置数据
  final _loaded = signal<bool>(false);
  final _loadedIdx = signal<bool>(false);
  final _motionProfile = signal<schema.MotionProfile?>(null);
  List<schema.VirtualPath> _virtualPaths = [];

  // 加载锁
  final _loadMpLock = signal<bool>(false);

  // 运动状态
  final _runState = signal<RunState>(.idle); // 运动状态
  final _runSpeed = signal<double>(0); // 运动速度
  final _runDistance = signal<double>(0); // 运动距离（服务器）
  final _runRealDistance = signal<double>(0); // 实际运动距离
  final _runDuration = signal<Duration>(Duration.zero); // 运动时长

  // 运动计时器
  Timer? _runTimer;

  // API客户端
  ApiClient? _apiClient;
  // 当前运动数据
  String? placeName;
  String? placeCode;
  String? sportCode;
  // 上传数据缓冲
  final _uploadBuf = signal<List<TrajPoint>>([]);

  // 地图绘制数据
  BMFMarker? _previewStartMarker;
  BMFMarker? _playMarker;
  BMFPolyline? _previewLine;
  BMFPolyline? _playLine;

  @override
  void initState() {
    checkAndRequestPermissions(PermissionType.location);

    _animeCtrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animeCtrl,
      curve: Curves.fastEaseInToSlowEaseOut,
    );

    _selectCtrlMp = FSelectController();

    super.initState();

    // 加载运动索引数据
    initIndex().then((v) {
      return _loadedIdx.value =
          globalMpIndex.value.isNotEmpty && globalVpIndex.value.isNotEmpty;
    });
  }

  @override
  void dispose() {
    stopLocationService();
    stopHeadingService();
    stopAutoRunning();
    _motionSimService?.dispose();
    _mapController = null;
    super.dispose();
  }

  /// 预览运动路径
  void previewPath(schema.VirtualPath p) {
    clearPreview();
    final path = p.points.map((v) => BMFCoordinate(v.lat, v.lng)).toList();
    _previewLine = BMFPolyline(
      coordinates: path,
      width: 8,
      dottedLine: false,
      colors: [Colors.red],
      lineCapType: BMFLineCapType.LineCapButt,
      lineJoinType: BMFLineJoinType.LineJoinRound,
    );
    _previewStartMarker = BMFMarker.icon(
      position: path.first,
      icon: "assets/icon/icon_start.png",
      identifier: "preview_start_marker",
      scaleX: 1.5,
      scaleY: 1.5,
      anchorX: 0.5,
      anchorY: 1,
    );
    _mapController?.addPolyline(_previewLine!);
    _mapController?.addMarker(_previewStartMarker!);
    _mapController?.setCenterCoordinate(path.first, true);
  }

  // 加载运动数据
  Future<bool> loadMotionData(String id) async {
    if (_loadMpLock.value) return false;
    _loadMpLock.value = true;
    if (globalMpIndex.value[id] == null) {
      _loadMpLock.value = false;
      return false;
    }
    _loaded.value = false;
    clearPreview();
    _virtualPaths.clear();
    _motionProfile.value = null;
    _motionProfile.value = await getMotionProfile(
      globalMpIndex.value[id]!.path,
    );
    if (_motionProfile.value == null) {
      _loadMpLock.value = false;
      return false;
    }

    placeName = _motionProfile.value!.data.ext!["placeName"];
    placeCode = _motionProfile.value!.data.ext!["placeCode"];

    for (final path in _motionProfile.value!.data.paths) {
      if (globalVpIndex.value[path] == null) continue;
      var vp = await getVirtualPath(globalVpIndex.value[path]!.path);

      if (vp == null) continue;

      _virtualPaths.add(vp);
    }

    if (_virtualPaths.isEmpty) {
      _loadMpLock.value = false;
      return false;
    }
    previewPath(_virtualPaths[0]);
    _loaded.value = true;
    _loadMpLock.value = false;
    return true;
  }

  // 开始自动运动
  Future<void> startAutoRunning(BuildContext context) async {
    if (_motionProfile.value == null) return;
    if (_virtualPaths.isEmpty) return;

    // 清理上次数据
    clearAutoRunning();
    _uploadBuf.value.clear();
    _runDuration.value = Duration.zero;

    _motionSimService = MotionSimulationService();

    // 保持屏幕常亮
    WakelockPlus.enable();

    // 获取登录凭证
    AuthCredential? auth = authManager.getAuth(providerId);

    if (auth == null) {
      toastification.show(
        context: context,
        title: const Text("操作失败"),
        description: const Text("未登录，请先登录"),
        autoCloseDuration: const Duration(seconds: 3),
        primaryColor: Colors.red,
        icon: Icon(LucideIcons.circleX),
      );
      return;
    }

    // 创建API客户端
    _apiClient = ApiClient(auth);

    // 创建虚拟路径
    final VirtualPath virtualPath = VirtualPath(
      id: _virtualPaths[0].id,
      name: _virtualPaths[0].name,
      points: _virtualPaths[0].points
          .map((p) => TrajectoryPoint(latitude: p.lat, longitude: p.lng))
          .toList(),
      length: 402.34,
    );
    final motionProfile = MotionProfile(
      id: _motionProfile.value!.id,
      name: _motionProfile.value!.name,
      virtualPaths: [virtualPath],
      playbackMode: .loop,
    );
    TrajectoryPoint? lastpoint;

    // 监听位置更新
    _motionSimService!.currentPosition.subscribe((position) {
      if (position != null) {
        print('位置更新: ${position.latitude}, ${position.longitude}');
        BMFCoordinate pos = BMFCoordinate(
          position.latitude,
          position.longitude,
        );
        if (_playLine == null) {
          if (lastpoint != null) {
            _playLine = BMFPolyline(
              coordinates: [
                BMFCoordinate(lastpoint!.latitude, lastpoint!.longitude),
                pos,
              ],
              width: 8,
              dottedLine: false,
              colors: [Colors.blue],
              lineCapType: BMFLineCapType.LineCapButt,
              lineJoinType: BMFLineJoinType.LineJoinRound,
            );
            _playMarker = BMFMarker.icon(
              position: pos,
              icon: "assets/icon/icon_blue_point.png",
              identifier: "play_marker",
              scaleX: 1.5,
              scaleY: 1.5,
              anchorX: 0.5,
              anchorY: 0.5,
            );
            _mapController?.addPolyline(_playLine!);
            _mapController?.addMarker(_playMarker!);
          }
        } else {
          _playLine!.updateCoordinates(_playLine!.coordinates + [pos]);
          _playMarker!.updatePosition(pos);

          _runRealDistance.value =
              _runRealDistance.value +
              haversineDistance(
                position.latitude,
                position.longitude,
                lastpoint!.latitude,
                lastpoint!.longitude,
              );
        }
        _uploadBuf.add(
          TrajPoint(
            coordinate: Coordinate(
              lat: position.latitude,
              lng: position.longitude,
            ),
            time: DateTime.now(),
          ),
        );
        lastpoint = position;
      }
    });

    // 监听运动速度
    _motionSimService!.currentOutput.subscribe((output) {
      if (output != null) {
        print('速度: ${output.speed.toStringAsFixed(2)} m/s');
        _runSpeed.value = output.speed;
      }
    });

    // 监听运动结束
    _motionSimService!.isRunning.subscribe((v) {
      if (!v && _runState.value == .running) {
        _apiClient?.endMotion(sportCode!);

        toastification.show(
          context: context,
          title: const Text("跑步完成"),
          description: const Text("跑步已结束，请在企业微信查看结果"),
          autoCloseDuration: const Duration(seconds: 5),
          primaryColor: Colors.green,
          icon: Icon(LucideIcons.circleCheck),
        );

        _runState.value = .idle;
        WakelockPlus.disable();
      }
    });

    // 监听上传缓冲区，并上传数据
    _uploadBuf.subscribe((v) async {
      if (v.length >= 8) {
        _apiClient?.uploadPoint(v, placeName!, placeCode!, sportCode!).then((
          v,
        ) {
          if (v != null) _runDistance.value = v.mileage * 1000;
        });

        _uploadBuf.value.clear();
        _uploadBuf.value.add(v.last);
      }
    });

    // 开始运动
    _motionSimService!.startSimulation(
      motionProfile: motionProfile,
      pace: _runConfig.value.speed,
      refreshRate: 1000 / _runConfig.value.interval,
      targetDistance: _runConfig.value.distance,
    );

    _runTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _runDuration.value = Duration(seconds: _runDuration.value.inSeconds + 1);
    });

    _runState.value = .running;

    sportCode = await _apiClient?.startMotion(placeName!, placeCode!);
  }

  // 停止自动运动
  void stopAutoRunning() async {
    await _motionSimService?.stopSimulation();

    WakelockPlus.disable();
  }

  // 清空自动运动数据
  void clearAutoRunning() {
    _motionSimService?.dispose();
    _motionSimService = null;
    _runSpeed.value = 0;
    _runDistance.value = 0;
    if (_playLine != null) {
      _mapController?.removeOverlay(_playLine!.id);
    }
    if (_playMarker != null) {
      _mapController?.removeMarker(_playMarker!);
    }
    _playLine = null;
    _playMarker = null;
  }

  // 清空预览数据
  void clearPreview() {
    if (_previewLine != null) {
      _mapController?.removeOverlay(_previewLine!.id);
    }
    if (_previewStartMarker != null) {
      _mapController?.removeMarker(_previewStartMarker!);
    }
    _previewLine = null;
    _previewStartMarker = null;
  }

  // 暂停自动运动（未使用）
  void pauseAutoRunning() {
    if (_runState.value == .running) {
      _motionSimService?.pauseSimulation();
      _runState.value = .paused;
    }
  }

  // 恢复自动运动（未使用）
  void resumeAutoRunning() {
    if (_runState.value == .paused) {
      _motionSimService?.resumeSimulation();
      _runState.value = .running;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听信号变化，更新ValueNotifier
    effect(() {
      _runConfigNotifier.value = _runConfig.value;
    });

    return SafeArea(
      key: widgetKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: SizedBox.expand(
              child: BMFMapWidget(
                onBMFMapCreated: (controller) {
                  // 地图初始化操作
                  _mapController = controller;
                  _mapController?.showUserLocation(true); // 显示用户坐标

                  _mapController?.setMapDidLoadCallback(
                    callback: () async {
                      final context = widgetKey.currentContext;

                      await _mapController?.setUserTrackingMode(
                        .None,
                      ); // 用户追踪模式（注意：一定要在初始化时设置一次，否则无法正常显示坐标）
                      startHeadingService(); // 启用地理磁偏角服务
                      final result = await startLocationService(
                        LocationServiceOptions(
                          purpose: .sport,
                          interval: 1000,
                          coorType: .GCJ02,
                        ),
                      ); // 启用定位服务

                      if (!result) {
                        stopHeadingService();
                        stopLocationService();
                        if (context != null && context.mounted) {
                          toastification.show(
                            context: context,
                            title: const Text("定位服务启动失败"),
                            description: const Text("这会影响部分功能，请检查是否拥有定位权限"),
                            icon: Icon(LucideIcons.circleX),
                            autoCloseDuration: Duration(seconds: 5),
                            primaryColor: Colors.red,
                          );
                        }
                        return;
                      }

                      bool firstMove = false;

                      // 监听位置数据
                      effect(() {
                        _mapController?.updateLocationData(
                          BMFUserLocation(
                            location: BMFLocation(
                              coordinate: BMFCoordinate(
                                rawLat.value,
                                rawLng.value,
                              ),
                              course: rawHeading.value, // Android使用该值做坐标旋转
                            ),
                            heading: (Platform.isIOS)
                                ? BMFHeading(trueHeading: rawHeading.value)
                                : null, // iOS使用该值做坐标旋转
                          ),
                        );

                        if (rawLat.value != 0 &&
                            rawLng.value != 0 &&
                            !firstMove) {
                          _mapController?.setCenterCoordinate(
                            BMFCoordinate(rawLat.value, rawLng.value),
                            true,
                          );
                          firstMove = true;
                        }
                      });
                    },
                  );
                },
                mapOptions: _mapOption,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: SizedBox(
              width: 40,
              height: 40,
              child: FButton.icon(
                style: FButtonStyle.secondary(),
                onPress: () {
                  context.pop();
                },
                child: Icon(LucideIcons.arrowLeft),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: SizedBox(
              width: 40,
              height: 40,
              child: FButton.icon(
                style: FButtonStyle.secondary(),
                onPress: () {},
                child: Icon(LucideIcons.circleQuestionMark),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SizedBox(
              height: 100,
              child: FCard.raw(
                child: Stack(
                  children: [
                    Visibility(
                      visible: _runState.watch(context) == .idle,
                      child: Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: 100,
                        child: Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(16, 16, 16, 16),
                          child: FSelect.searchBuilder(
                            label: const Text('运动预设'),
                            control: FSelectControl<MapItem>.managed(
                              controller: _selectCtrlMp,
                              onChange: (value) {
                                if (value != null) loadMotionData(value.id);
                              },
                            ),
                            hint: "选择运动预设",
                            format: (MapItem value) => value.name,
                            contentAnchor: .bottomCenter,
                            fieldAnchor: .topCenter,
                            filter: (query) {
                              var lists = globalMpIndex.value.values;
                              if (query.isEmpty) return lists;
                              return lists.where(
                                (v) =>
                                    v.name.contains(query) ||
                                    v.id.contains(query),
                              );
                            },
                            contentBuilder:
                                (
                                  BuildContext context,
                                  String query,
                                  Iterable<MapItem> values,
                                ) => [
                                  for (final v in values)
                                    FSelectItem(title: Text(v.name), value: v),
                                ],
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _runState.watch(context) == .running,
                      child: Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: 100,
                        child: Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(16, 8, 8, 8),
                          child: Column(
                            mainAxisAlignment: .center,
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                '${_runSpeed.watch(context).toStringAsFixed(2)}m/s',
                                textAlign: .left,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: .bold,
                                ),
                              ),
                              Text(
                                '耗时: ${_runDuration.watch(context).toString().split('.').first}',
                                textAlign: .left,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '里程: ${_runRealDistance.watch(context).toStringAsFixed(2)}(${_runDistance.watch(context).toStringAsFixed(2)})m',
                                textAlign: .left,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 100,
                      child: Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: FButton.icon(
                            style: FButtonStyle.primary(),
                            onPress: (_loaded.watch(context))
                                ? () {
                                    switch (_runState.value) {
                                      case .running:
                                        showFDialog(
                                          context: context,
                                          builder:
                                              (
                                                context,
                                                style,
                                                animation,
                                              ) => FDialog(
                                                style: style,
                                                animation: animation,
                                                direction: Axis.horizontal,
                                                title: const Text("确认结束？"),
                                                body: Text(
                                                  "未达到预计里程：${_runDistance.value}/${_runConfig.value.distance} m，结束后将自动提交数据。是否继续？",
                                                ),
                                                actions: [
                                                  FButton(
                                                    style:
                                                        FButtonStyle.outline(),
                                                    onPress: () => Navigator.of(
                                                      context,
                                                    ).pop(),
                                                    child: const Text('取消'),
                                                  ),
                                                  FButton(
                                                    onPress: () {
                                                      stopAutoRunning();
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: const Text("结束"),
                                                  ),
                                                ],
                                              ),
                                        );
                                        break;
                                      case .idle:
                                        showFDialog(
                                          context: context,
                                          builder:
                                              (
                                                context,
                                                style,
                                                animation,
                                              ) => FDialog(
                                                style: style,
                                                animation: animation,
                                                direction: Axis.horizontal,
                                                title: const Text("确认开跑？"),
                                                body: Text(
                                                  "目前配置：\n  预设：${_motionProfile.value!.name}\n  配速：${_runConfig.value.speed} m/s\n  预计里程：${_runConfig.value.distance} m",
                                                ),
                                                actions: [
                                                  FButton(
                                                    style:
                                                        FButtonStyle.outline(),
                                                    onPress: () => Navigator.of(
                                                      context,
                                                    ).pop(),
                                                    child: const Text('取消'),
                                                  ),
                                                  FButton(
                                                    onPress: () {
                                                      startAutoRunning(context);
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: const Text("Go!"),
                                                  ),
                                                ],
                                              ),
                                        );
                                        break;
                                      default:
                                        break;
                                    }
                                  }
                                : null,
                            child: (_runState.watch(context) == .running)
                                ? Icon(LucideIcons.square)
                                : Icon(LucideIcons.play),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 120,
            child: Row(
              spacing: 8,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FButton.icon(
                    style: FButtonStyle.secondary(),
                    onPress: () {
                      WoltModalSheet.show(
                        context: context,
                        pageListBuilder: (ctx) => [
                          WoltModalSheetPage(
                            child: Padding(
                              padding: .fromLTRB(16, 0, 16, 16),
                              child: ValueListenableBuilder(
                                valueListenable: _runConfigNotifier,
                                builder: (ctx, value, child) => Column(
                                  spacing: 8,
                                  children: [
                                    const Text(
                                      "跑步配置",
                                      textAlign: .left,
                                      style: TextStyle(
                                        fontWeight: .bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    FTextField(
                                      // controller: _textCtrlSpeed,
                                      control: FTextFieldControl.managed(
                                        controller: _textCtrlSpeed,

                                        onChange: (v) {
                                          _runConfig.value = value.copyWith(
                                            speed:
                                                double.tryParse(v.text) ?? 3.2,
                                          );
                                        },
                                      ),
                                      label: const Text("配速"),
                                      description: const Text("模拟运动的配速（米/秒）"),
                                      hint: "默认: 3.2",
                                      keyboardType:
                                          TextInputType.numberWithOptions(),
                                      onEditingComplete: () {
                                        _textCtrlSpeed.text = value.speed
                                            .toString();
                                      },
                                    ),
                                    FTextField(
                                      // controller: _textCtrlDistance,
                                      control: FTextFieldControl.managed(
                                        controller: _textCtrlDistance,
                                        onChange: (v) {
                                          _runConfig.value = value.copyWith(
                                            distance:
                                                double.tryParse(v.text) ?? 2100,
                                          );
                                        },
                                      ),
                                      label: const Text("里程"),
                                      description: const Text("模拟运动里程（米）"),
                                      hint: "默认: 2100",
                                      keyboardType:
                                          TextInputType.numberWithOptions(),

                                      onEditingComplete: () {
                                        _textCtrlDistance.text = value.distance
                                            .toString();
                                      },
                                    ),
                                    AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, child) => FCollapsible(
                                        value: _animation.value,
                                        child: Column(
                                          children: [
                                            FDivider(
                                              style: (sty) {
                                                return FDividerStyle(
                                                  color: Colors.grey,
                                                  padding: sty.padding,
                                                );
                                              },
                                            ),
                                            FTextField(
                                              // controller: _textCtrlInterval,
                                              control:
                                                  FTextFieldControl.managed(
                                                    controller:
                                                        _textCtrlInterval,
                                                    onChange: (v) {
                                                      _runConfig.value = value
                                                          .copyWith(
                                                            interval:
                                                                int.tryParse(
                                                                  v.text,
                                                                ) ??
                                                                1000,
                                                          );
                                                    },
                                                  ),
                                              label: const Text("刷新间隔"),
                                              description: const Text(
                                                "坐标点刷新的间隔时间（毫秒）",
                                              ),
                                              hint: "默认: 1000",
                                              keyboardType:
                                                  TextInputType.numberWithOptions(),

                                              onEditingComplete: () {
                                                _textCtrlInterval.text = value
                                                    .interval
                                                    .toString();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: FButton(
                                        style: FButtonStyle.ghost(),
                                        onPress: () => _animeCtrl.toggle(),
                                        child: Text("展开/收起高级选项"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    child: Icon(LucideIcons.bolt),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FButton.icon(
                    style: FButtonStyle.secondary(),
                    onPress: () {},
                    child: Icon(LucideIcons.notepadText),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FButton.icon(
                    style: FButtonStyle.secondary(),
                    onPress: () {
                      _mapController?.setCenterCoordinate(
                        BMFCoordinate(rawLat.value, rawLng.value),
                        true,
                      );
                    },
                    child: Icon(LucideIcons.locateFixed),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            bottom: 120,
            child: Visibility(
              visible: (_runState.watch(context) == RunState.running),
              child: Container(
                alignment: .centerLeft,
                decoration: BoxDecoration(
                  borderRadius: .only(
                    topLeft: .circular(4),
                    bottomLeft: .circular(4),
                  ),
                  gradient: const LinearGradient(
                    begin: .centerLeft,
                    end: .centerRight,
                    colors: [Colors.green, Colors.transparent],
                  ),
                ),
                padding: .fromLTRB(12, 6, 16, 6),
                child: const Text(
                  "自动跑步中...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
