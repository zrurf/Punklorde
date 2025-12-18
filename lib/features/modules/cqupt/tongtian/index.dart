import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/utils/lbs/distance.dart';
import 'package:punklorde/common/utils/permission/checker.dart';
import 'package:punklorde/common/models/location.dart' as modLoc;
import 'package:punklorde/core/services/lbs/location.dart';
import 'package:punklorde/core/services/motion_simulator/model.dart';
import 'package:punklorde/core/services/motion_simulator/simulator.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/api/api.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/data.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/model.dart'
    hide VirtualPath, MotionProfile;
import 'package:punklorde/features/modules/cqupt/tongtian/model/auth.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/views/widgets/bar.dart';
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

  final BMFMapOptions _mapOption = BMFMapOptions(
    center: BMFCoordinate(39.965, 116.404),
    zoomLevel: 18,
    buildingsEnabled: true,
  );

  late final AnimationController _animeCtrl;
  late final Animation<double> _animation;

  BMFMapController? _mapController;

  MotionSimulationService? _motionSimService;

  final _runState = signal<RunState>(.idle);
  final _runSpeed = signal<double>(0);
  final _runDistance = signal<double>(0);

  late final FSelectController<MapItem> _selectCtrlMp;
  final _textCtrlOpenid = TextEditingController(text: "");
  final _textCtrlSpeed = TextEditingController(text: "3.2");
  final _textCtrlInterval = TextEditingController(text: "1000");
  final _textCtrlDistance = TextEditingController(text: "2100");

  final _loaded = signal<bool>(false);
  final _loadedIdx = signal<bool>(false);
  final _motionProfile = signal<schema.MotionProfile?>(null);
  List<schema.VirtualPath> _virtualPaths = [];

  final _loadMpLock = signal<bool>(false);

  ApiClient? _apiClient;

  String? placeName;
  String? placeCode;
  String? sportCode;

  final _uploadBuf = signal<List<modLoc.TrajPoint>>([]);

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

    _selectCtrlMp = FSelectController(vsync: this);

    super.initState();
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
  }

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

  Future<void> startAutoRunning() async {
    if (_motionProfile.value == null) return;
    if (_virtualPaths.isEmpty) return;

    clearAutoRunning();
    _motionSimService = MotionSimulationService();

    WakelockPlus.enable();

    ModTongtianAuth? auth;
    if (authStatus.value.containsKey("MOD_TONGTIAN_AUTH")) {
      auth = authStatus.value["MOD_TONGTIAN_AUTH"] as ModTongtianAuth;
      if (auth.openid != _textCtrlOpenid.text) {
        auth = null;
      }
    }

    auth = await getTongtianAuth(_textCtrlOpenid.text);
    if (auth == null) {
      print("_ERR: 无法获取登录信息");
      return;
    }

    auth.openid = _textCtrlOpenid.text;

    authStatus.value["MOD_TONGTIAN_AUTH"] = auth;

    _apiClient = ApiClient(auth);

    _uploadBuf.value.clear();

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
          /*
          _runDistance.value =
              _runDistance.value +
              haversineDistance(
                position.latitude,
                position.longitude,
                lastpoint!.latitude,
                lastpoint!.longitude,
              );
          */
        }
        _uploadBuf.add(
          modLoc.TrajPoint(
            coordinate: modLoc.Coordinate(
              lat: position.latitude,
              lng: position.longitude,
            ),
            time: DateTime.now(),
          ),
        );
        lastpoint = position;
      }
    });

    _motionSimService!.currentOutput.subscribe((output) {
      if (output != null) {
        print('速度: ${output.speed.toStringAsFixed(2)} m/s');
        _runSpeed.value = output.speed;
      }
    });

    _motionSimService!.isRunning.subscribe((v) {
      if (!v && _runState.value == .running) {
        _apiClient?.endMotion(sportCode!);
        _runState.value = .idle;
        WakelockPlus.disable();
      }
    });

    _motionSimService!.startSimulation(
      motionProfile: motionProfile,
      pace: _runConfig.value.speed,
      refreshRate: 1000 / _runConfig.value.interval,
      targetDistance: _runConfig.value.distance,
    );

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

    _runState.value = .running;

    sportCode = await _apiClient?.startMotion(placeName!, placeCode!);
  }

  void stopAutoRunning() async {
    await _motionSimService?.stopSimulation();
    WakelockPlus.disable();
  }

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

  void pauseAutoRunning() {
    if (_runState.value == .running) {
      _motionSimService?.pauseSimulation();
      _runState.value = .paused;
    }
  }

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

    initIndex().then((v) {
      return _loadedIdx.value =
          globalMpIndex.value.isNotEmpty && globalVpIndex.value.isNotEmpty;
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
                          child: FSelect<MapItem>.searchBuilder(
                            controller: _selectCtrlMp,
                            label: const Text('运动预设'),
                            hint: "选择运动预设",
                            onChange: (value) {
                              if (value != null) loadMotionData(value.id);
                            },
                            anchor: .bottomCenter,
                            fieldAnchor: .topCenter,
                            format: (MapItem value) => value.name,
                            filter: (query) {
                              var lists = globalMpIndex.watch(context).values;
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
                          padding: EdgeInsetsGeometry.fromLTRB(32, 8, 8, 8),
                          child: Column(
                            mainAxisAlignment: .center,
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                '${_runSpeed.watch(context).toStringAsFixed(2)} m/s',
                                textAlign: .left,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: .bold,
                                ),
                              ),
                              Text(
                                '运动里程：${_runDistance.watch(context).toStringAsFixed(2)} m',
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
                                                      startAutoRunning();
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
                                      "账号配置",
                                      textAlign: .left,
                                      style: TextStyle(
                                        fontWeight: .bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    FTextField(
                                      controller: _textCtrlOpenid,
                                      label: const Text("Open ID"),
                                      description: const Text(
                                        "微信登录小程序时的Open ID",
                                      ),
                                    ),
                                    const Text(
                                      "跑步配置",
                                      textAlign: .left,
                                      style: TextStyle(
                                        fontWeight: .bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    FTextField(
                                      controller: _textCtrlSpeed,
                                      label: const Text("配速"),
                                      description: const Text("模拟运动的配速（米/秒）"),
                                      hint: "默认: 3.2",
                                      keyboardType:
                                          TextInputType.numberWithOptions(),
                                      onChange: (v) {
                                        _runConfig.value = value.copyWith(
                                          speed: double.tryParse(v) ?? 3.2,
                                        );
                                      },
                                      onEditingComplete: () {
                                        _textCtrlSpeed.text = value.speed
                                            .toString();
                                      },
                                    ),
                                    FTextField(
                                      controller: _textCtrlDistance,
                                      label: const Text("里程"),
                                      description: const Text("模拟运动里程（米）"),
                                      hint: "默认: 2100",
                                      keyboardType:
                                          TextInputType.numberWithOptions(),
                                      onChange: (v) {
                                        _runConfig.value = value.copyWith(
                                          distance: double.tryParse(v) ?? 2100,
                                        );
                                      },
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
                                              controller: _textCtrlInterval,
                                              label: const Text("刷新间隔"),
                                              description: const Text(
                                                "坐标点刷新的间隔时间（毫秒）",
                                              ),
                                              hint: "默认: 1000",
                                              keyboardType:
                                                  TextInputType.numberWithOptions(),
                                              onChange: (v) {
                                                _runConfig.value = value
                                                    .copyWith(
                                                      interval:
                                                          int.tryParse(v) ??
                                                          1000,
                                                    );
                                              },
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
