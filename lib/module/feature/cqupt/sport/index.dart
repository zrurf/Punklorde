import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/client.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/resource/resource.dart';
import 'package:punklorde/module/feature/cqupt/sport/service/map.dart';
import 'package:punklorde/module/feature/cqupt/sport/service/sport.dart';
import 'package:punklorde/module/feature/cqupt/sport/utils/time.dart';
import 'package:punklorde/module/feature/cqupt/sport/view/widgets/config_pannel.dart';
import 'package:punklorde/module/feature/cqupt/sport/view/widgets/user_panel.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/sport.dart';
import 'package:punklorde/module/service/lbs/location.dart';
import 'package:punklorde/src/rust/services/motion_sim/model.dart';
import 'package:punklorde/utils/permission.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FeatCquptSportView extends StatefulWidget {
  const FeatCquptSportView({super.key});

  @override
  State<FeatCquptSportView> createState() => _FeatCquptSportViewState();
}

class _FeatCquptSportViewState extends State<FeatCquptSportView>
    with TickerProviderStateMixin {
  final GlobalKey<_FeatCquptSportViewState> widgetKey = GlobalKey();

  // 地图参数
  final BMFMapOptions _mapOption = BMFMapOptions(
    center: BMFCoordinate(29.53282, 106.60756),
    zoomLevel: 18,
    buildingsEnabled: true,
    showZoomControl: false,
  );

  // 服务组件
  InnerMapService? _mapService;
  InnerSportService? _sportService;

  // Api组件
  final ApiClient _apiClient = ApiClient();

  // 运行模式
  final Signal<SportMode> _mode = Signal<SportMode>(.auto);
  // 运行状态
  final Signal<bool> _isRunning = Signal<bool>(false);
  final _duration = signal(const Duration(seconds: 0)); // 运动时长
  final _remainTime = signal(const Duration(seconds: 0)); // 剩余时间
  final _distance = signal(0.0); // 当前距离
  final _speed = signal(0.0); // 速度

  // 定时器
  Timer? _updateTimer;

  @override
  void initState() {
    // 申请权限
    checkAndRequestPermission(.location);
    checkAndRequestPermission(.notice);
    _mapService = InnerMapService();
    _sportService = InnerSportService();

    final user = authManager.getPrimaryAuthByPlatform(platCquptSport.id);
    if (user != null && user.isValid()) {
      _changeUser(user);
    }

    loadReourceIndex();

    super.initState();
  }

  @override
  void dispose() {
    stopLocationService();
    stopHeadingService();
    _stopSport();
    _mapService?.stop();
    _sportService = null;
    _mapService = null;
    super.dispose();
  }

  void _exit() {
    if (!_isRunning.value) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return PopScope(
      key: widgetKey,
      canPop: !_isRunning.watch(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (_isRunning.value) {
          toastification.show(
            context: context,
            title: Text(t.submodule.cqupt_sport.tip_need_stop),
            autoCloseDuration: const Duration(seconds: 3),
            animationDuration: const Duration(milliseconds: 300),
            primaryColor: Colors.red,
            icon: const Icon(LucideIcons.circleX),
          );
        }
      },
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SizedBox.expand(
                child: BMFMapWidget(
                  mapOptions: _mapOption,
                  onBMFMapCreated: (controller) {
                    _mapService?.init(controller);
                    _mapService?.mapController.showUserLocation(true); // 显示用户定位
                    _mapService?.mapController.setMapDidLoadCallback(
                      callback: _mapLoadCallback,
                    ); // 地图加载完成回调
                  },
                ),
              ),
            ),
            // 顶部功能栏
            Visibility(
              visible: !_isRunning.watch(context),
              child: Positioned(
                left: 12,
                right: 12,
                top: 12,
                height: 40,
                child: Row(
                  spacing: 4,
                  children: [
                    FButton.icon(
                      variant: .outline,
                      size: .sm,
                      onPress: () {
                        _exit();
                      },
                      child: const Icon(LucideIcons.arrowLeft),
                    ),
                    SizedBox(
                      height: .infinity,
                      width: 180,
                      child: FSelect<SportMode>.rich(
                        size: .sm,
                        control: .managed(
                          initial: _mode.value,
                          toggleable: false,
                          onChange: (SportMode? value) =>
                              _mode.value = value ?? .auto,
                        ),
                        hint: t.submodule.cqupt_sport.choose_mode,
                        format: (value) => modeNames[value] ?? "",
                        children: [
                          .item(
                            prefix: Icon(
                              LucideIcons.refreshCw,
                              color: colors.primary,
                            ),
                            title: Text(
                              t.submodule.cqupt_sport.mode_auto_run,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              t.submodule.cqupt_sport.mode_auto_run_tip,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                            ),
                            value: SportMode.auto,
                          ),
                          .item(
                            prefix: Icon(
                              LucideIcons.play,
                              color: colors.primary,
                            ),
                            title: Text(
                              t.submodule.cqupt_sport.mode_normal_run,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              t.submodule.cqupt_sport.mode_normal_run_tip,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                            ),
                            value: SportMode.normal,
                            enabled: false, // 暂不启用
                          ),
                          .item(
                            prefix: Icon(
                              LucideIcons.route,
                              color: colors.primary,
                            ),
                            title: Text(
                              t.submodule.cqupt_sport.mode_traj_record,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              t.submodule.cqupt_sport.mode_traj_record_tip,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                            ),
                            value: SportMode.record,
                            enabled: false, // 暂不启用
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    FButton.icon(
                      variant: .outline,
                      size: .sm,
                      onPress: () {},
                      child: const Icon(LucideIcons.info),
                    ),
                  ],
                ),
              ),
            ),
            // 跑步状态栏
            Visibility(
              visible: _isRunning.watch(context),
              child: Positioned(
                left: 12,
                right: 12,
                top: 12,
                height: 120,
                child: FCard.raw(
                  style: .delta(
                    decoration: .boxDelta(
                      color: const Color(0xE01d1d1f),
                      border: .all(color: const Color(0xF01d1d1f), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xE01d1d1f),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        // 顶部数据区域
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 运动时间
                              _buildStatColumn(
                                context,
                                mainValue: formatDuration(
                                  _duration.watch(context),
                                ),
                                mainLabel: t.submodule.cqupt_sport.elapsed_time,
                                subValue:
                                    '${t.submodule.cqupt_sport.remain_time} ${formatDuration(_remainTime.watch(context))}',
                                alignment: CrossAxisAlignment.center,
                              ),

                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),

                              // 运动距离
                              _buildStatColumn(
                                context,
                                mainValue:
                                    "${_distance.watch(context).round()}m",
                                mainLabel: t.submodule.cqupt_sport.distance,
                                subValue:
                                    '${t.submodule.cqupt_sport.target_distance} ${featUserConfig.watch(context).targetDistance.round()}m',
                                alignment: CrossAxisAlignment.center,
                              ),

                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),

                              // 速度/配速
                              _buildStatColumn(
                                context,
                                mainValue: formatPace(_speed.watch(context)),
                                mainLabel: t.submodule.cqupt_sport.pace,
                                subValue:
                                    '${t.submodule.cqupt_sport.speed} ${_speed.watch(context).toStringAsFixed(2)}m/s',
                                alignment: CrossAxisAlignment.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 底部进度条
                        _buildProgressBar(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 底部控制面板
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 100, // 面板高度
                decoration: BoxDecoration(
                  color: const Color(0xE01d1d1f).withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFF1d1d1f), width: 1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 顶部拖动条
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 按钮区域
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 左侧功能组
                          _buildSideButtons(
                            icon: LucideIcons.clipboardList,
                            label: t.submodule.cqupt_sport.record,
                            onTap: () {
                              if (_isRunning.value) {
                                toastification.show(
                                  context: context,
                                  title: Text(
                                    t.submodule.cqupt_sport.tip_need_stop,
                                  ),
                                  icon: const Icon(LucideIcons.circleX),
                                  autoCloseDuration: const Duration(seconds: 3),
                                  animationDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  primaryColor: Colors.red,
                                );
                              } else {
                                context.push("/feat/cqupt/sport/record");
                              }
                            },
                          ),
                          _buildSideButtons(
                            icon: LucideIcons.slidersHorizontal,
                            label: t.submodule.cqupt_sport.configure,
                            onTap: () {
                              if (_isRunning.value) {
                                toastification.show(
                                  context: context,
                                  title: Text(
                                    t.submodule.cqupt_sport.tip_need_stop,
                                  ),
                                  icon: const Icon(LucideIcons.circleX),
                                  autoCloseDuration: const Duration(seconds: 3),
                                  animationDuration: const Duration(
                                    microseconds: 300,
                                  ),
                                );
                                return;
                              }
                              showFSheet(
                                context: context,
                                builder: (sheetContext) => ConfigPanel(
                                  onSelectMotionProfile: () {
                                    final mp =
                                        featMotionProfile.value?.data?.paths[0];
                                    if (mp == null) {
                                      return;
                                    }
                                    final vp = featVirtualPaths.value?[mp];
                                    if (vp == null) {
                                      return;
                                    }
                                    _mapService?.drawPreviewPath(
                                      vp.points
                                          .map(
                                            (v) => Coordinate(
                                              lat: v.lat,
                                              lng: v.lng,
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                                side: .btt,
                              );
                            },
                          ),

                          // 中间主按钮
                          _buildMainButton(context),

                          // 右侧功能组
                          _buildSideButtons(
                            icon: LucideIcons.locateFixed,
                            label: t.submodule.cqupt_sport.locate,
                            onTap: () {
                              _mapService?.moveTo(rawLat.value, rawLng.value);
                            },
                          ),
                          _buildSideButtons(
                            icon: LucideIcons.userRound,
                            label: t.submodule.cqupt_sport.account,
                            onTap: () {
                              showFSheet(
                                context: context,
                                builder: (sheetContext) => UserPanel(
                                  currentUser: featCredential.watch(context),
                                  onSelect: (AuthCredential? credential) {
                                    if (_isRunning.value) {
                                      toastification.show(
                                        context: context,
                                        title: Text(
                                          t.submodule.cqupt_sport.tip_need_stop,
                                        ),
                                        icon: const Icon(LucideIcons.circleX),
                                        autoCloseDuration: const Duration(
                                          seconds: 3,
                                        ),
                                        animationDuration: const Duration(
                                          microseconds: 300,
                                        ),
                                      );
                                      return;
                                    }
                                    _changeUser(credential);
                                  },
                                ),
                                side: .btt,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String mainValue,
    required String mainLabel,
    required String subValue,
    required CrossAxisAlignment alignment,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignment,
        spacing: 4,
        children: [
          Text(
            mainLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          Text(
            mainValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'AlteDIN1451', // 使用数字专用字体
              letterSpacing: 1,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 构建底部进度条
  Widget _buildProgressBar(BuildContext context) {
    final distance = _distance.watch(context);
    final target = featUserConfig.watch(context).targetDistance;
    // 计算进度百分比，最大不超过1.0
    double progress = (target > 0) ? (distance / target) : 0.0;
    if (progress > 1.0) progress = 1.0;

    return Column(
      children: [
        // 进度数值标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '进度',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 进度条本体
        SizedBox(
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                // 背景槽
                Container(color: Colors.white.withValues(alpha: 0.1)),
                // 进度填充
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideButtons({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 中间的主操作按钮 (开始/结束)
  Widget _buildMainButton(BuildContext context) {
    final colors = context.theme.colors;
    final isRunning = _isRunning.watch(context);

    return GestureDetector(
      onTap: () {
        showFDialog(
          context: context,
          builder: (context, style, animation) {
            return FDialog(
              style: style,
              animation: animation,
              title: (isRunning)
                  ? Text(t.submodule.cqupt_sport.stop_run)
                  : Text(t.submodule.cqupt_sport.start_run),
              body: Column(
                mainAxisSize: .min,
                spacing: 8,
                children: [
                  Text(
                    (isRunning)
                        ? t.submodule.cqupt_sport.stop_run_tip
                        : t.submodule.cqupt_sport.start_run_tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                    textAlign: .center,
                  ),

                  _buildInfoField(
                    context,
                    title: t.title.user,
                    value: featCredential.value?.name ?? "",
                    icon: LucideIcons.userRound,
                    onLongPress: () {},
                  ),

                  _buildInfoField(
                    context,
                    title: t.submodule.cqupt_sport.distance,
                    value: (isRunning)
                        ? '${_distance.value.toString()} / ${featUserConfig.value.targetDistance.toString()} m'
                        : '${featUserConfig.value.targetDistance.toString()} m',
                    icon: LucideIcons.lineSquiggle,
                    onLongPress: () {},
                  ),

                  _buildInfoField(
                    context,
                    title: (isRunning)
                        ? t.submodule.cqupt_sport.progress
                        : t.submodule.cqupt_sport.speed,
                    value: (isRunning)
                        ? '${(featUserConfig.value.targetDistance > 0) ? ((min(_distance / featUserConfig.value.targetDistance, 1)) * 100).toStringAsFixed(2) : 0.0} %'
                        : '${featUserConfig.value.speed.toString()} m/s',
                    icon: LucideIcons.gauge,
                    onLongPress: () {},
                  ),
                ],
              ),
              actions: [
                FButton(
                  size: .xs,
                  onPress: () {
                    if (isRunning) {
                      // 停止运动
                      _stopSport();
                    } else {
                      // 开始运动
                      _startSport();
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(t.notice.confirm),
                ),
                FButton(
                  onPress: () {
                    Navigator.of(context).pop();
                  },
                  size: .xs,
                  variant: .secondary,
                  child: Text(t.notice.cancel),
                ),
              ],
            );
          },
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isRunning ? 80 : 140,
        height: 65,
        decoration: BoxDecoration(
          color: isRunning ? const Color(0xFFFF3B30) : const Color(0xFF30D158),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: (isRunning ? Colors.red : Colors.green).withValues(
                alpha: 0.3,
              ),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isRunning
                ? const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 36,
                    key: ValueKey('stop'),
                  )
                : Row(
                    key: ValueKey('start'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.submodule.cqupt_sport.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _mapLoadCallback() async {
    final context = widgetKey.currentContext;

    await _mapService?.mapController.setUserTrackingMode(
      .None,
    ); // 用户追踪模式（注意：一定要在初始化时设置一次，否则无法正常显示）

    await startHeadingService(); // 开启地理磁偏角服务
    final result = await startLocationService(
      LocationServiceOptions(purpose: .sport, interval: 1000, coorType: .GCJ02),
    ); // 启用定位服务
    if (!result) {
      stopHeadingService();
      stopLocationService();
      if (context != null && context.mounted) {
        toastification.show(
          context: context,
          title: Text(t.notice.location_service_failed),
          description: Text(t.notice.location_service_failed_msg),
          icon: const Icon(LucideIcons.circleX),
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
          primaryColor: Colors.red,
        );
      }
      return;
    }
    effect(() {
      _mapService?.mapController.updateLocationData(
        BMFUserLocation(
          location: BMFLocation(
            coordinate: BMFCoordinate(rawLat.value, rawLng.value),
            course: rawHeading.value,
          ),
          heading: (Platform.isIOS)
              ? BMFHeading(trueHeading: rawHeading.value)
              : null,
        ),
      );
    });

    EffectCleanup? centerEffect;
    centerEffect = effect(() {
      final lat = rawLat.value;
      final lng = rawLng.value;

      if (lat != 0 && lng != 0) {
        _mapService?.mapController.setCenterCoordinate(
          BMFCoordinate(lat, lng),
          true,
        );
        centerEffect?.call();
      }
    });
  }

  // 切换用户
  void _changeUser(AuthCredential? cred) {
    featCredential.value = cred;
  }

  Future<bool> _startSport() async {
    if (_isRunning.value) {
      return false;
    }

    if (featCredential.value == null) {
      toastification.show(
        context: widgetKey.currentContext,
        title: Text(t.notice.unselected_user),
        icon: const Icon(LucideIcons.circleX),
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
        primaryColor: Colors.red,
      );
      return false;
    }

    if (featPlaceCode.value == null ||
        featPlaceName.value == null ||
        featMotionProfile.value == null ||
        featVirtualPaths.value == null) {
      toastification.show(
        context: widgetKey.currentContext,
        title: Text(t.notice.wait_reource_load),
        icon: const Icon(LucideIcons.circleX),
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
        primaryColor: Colors.red,
      );
      return false;
    }

    final mode = _mode.value;
    if ((mode == .normal || mode == .record) &&
        !await checkAndRequestPermission(.location)) {
      return false;
    }
    final ok =
        await _sportService?.start(
          InnerSportServiceConfig(
            mode: mode,
            placeCode: featPlaceCode.value!,
            placeName: featPlaceName.value!,
            startCaallback: sportStartCallback,
            stopCallback: sportStopCallback,
            recordCallback: sportRecordCallback,
            uploadCallback: sportUploadCallback,
            retryUploadCallback: sportRetryUploadCallback,
            autoRunConfig: AutoRunningConfig(
              placeCode: featPlaceCode.value!,
              placeName: featPlaceName.value!,
              updateFrequency: featUserConfig.value.interval,
              targetDistance: featUserConfig.value.targetDistance,
              simulatorConfig: SimulatorConfig(
                targetSpeed: featUserConfig.value.speed,
                minSpeed:
                    featUserConfig.value.speed -
                    featUserConfig.value.speedJitterAmplitude,
                maxSpeed:
                    featUserConfig.value.speed +
                    featUserConfig.value.speedJitterAmplitude,
                acceleration: 3,
                deceleration: 3,
                stepFrequency: 150,
                strideLength: 0.8,
                gpsRefreshRate: 1,
                accelerometerRefreshRate: 1,
                gyroscopeRefreshRate: 0,
                compassRefreshRate: 0,
                barometerRefreshRate: 0,
                jitterSeed: featUserConfig.value.seedToBigInt(),
                positionJitterAmplitude:
                    featUserConfig.value.positionJitterAmplitude,
                speedJitterAmplitude: featUserConfig.value.speedJitterAmplitude,
                bearingJitterAmplitude: 5,
                accelerometerJitterAmplitude: 0.4,
                gyroscopeJitterAmplitude: 0,
                jitterFrequencyScale: 0.12,
                trajectoryMode: (featVirtualPaths.value?.length != 1)
                    ? .sequential
                    : .loop,
                loopCount: 0,
                forbiddenZones: [],
                fenceWarningDistance: 3,
                checkpoints: [],
                checkpointTolerance: 5,
                autoRouteToCheckpoint: false,
                checkpointStayTime: 0,
                pathfindingGridResolution: 100,
                smoothingFactor: 0.8,
                baseAltitude: 400,
                altitudeVariation: 0,
              ),
              trajectories:
                  featMotionProfile.value?.data?.paths
                      .map((v) {
                        final vp = featVirtualPaths.value?[v];
                        if (vp == null) return null;
                        return Trajectory(
                          id: vp.id,
                          name: vp.name,
                          points: vp.points
                              .map(
                                (v1) => GeoPoint(
                                  latitude: v1.lat,
                                  longitude: v1.lng,
                                ),
                              )
                              .toList(),
                        );
                      })
                      .nonNulls
                      .toList() ??
                  [],
            ),
          ),
        ) ??
        false;
    if (!ok) return false;
    WakelockPlus.enable();
    _isRunning.value = true;

    _duration.value = Duration.zero;
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration.value += const Duration(seconds: 1);
    });
    _mapService?.clearPlayPath();
    final firstPoint = featVirtualPaths
        .value?[featMotionProfile.value?.data?.paths.first ?? '']
        ?.points
        .first;
    if (firstPoint == null) {
      _stopSport();
      return false;
    }
    _mapService?.initPlayPath(
      (mode == .auto)
          ? Coordinate(lat: firstPoint.lat, lng: firstPoint.lng)
          : Coordinate(lat: rawLat.value, lng: rawLng.value),
      mode == .auto,
    );
    _mapService?.moveTo(firstPoint.lat, firstPoint.lng);
    _mapService?.scala(19);
    return true;
  }

  Future<void> _stopSport() async {
    await _sportService?.stop();
    _updateTimer?.cancel();
    _updateTimer = null;
    WakelockPlus.disable();
    _isRunning.value = false;
  }

  Future<String?> sportStartCallback() async {
    final sportId = await _apiClient.startSport(
      featPlaceName.value!,
      featPlaceCode.value!,
    );

    if (sportId == null) {
      toastification.show(
        context: widgetKey.currentContext,
        title: Text(t.notice.sport_start_failed),
        icon: const Icon(LucideIcons.circleX),
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
        primaryColor: Colors.red,
      );
      await _stopSport();
      return null;
    }
    return (_mode.value == .record) ? "_punklorde_record" : sportId;
  }

  Future<void> sportStopCallback(String sportId) async {
    await _apiClient.endSport(sportId);
  }

  Future<void> sportRecordCallback(String sportId, TrajPoint point) async {
    _speed.value = _sportService?.getSpeed ?? 0; // 更新速度
    _mapService?.updatePlayPath(point.coordinate); // 添加轨迹点
    final remainDistance =
        featUserConfig.value.targetDistance - _distance.value;
    _remainTime.value = Duration(
      milliseconds: (_speed.value > 0 && remainDistance > 0)
          ? (remainDistance / _speed.value * 1000).round()
          : 0,
    ); // 更新剩余时长
  }

  Future<UploadCallbackRsult?> sportUploadCallback(
    String sportId,
    List<TrajPoint> trajectory,
  ) async {
    final result = await _apiClient.uploadPoint(
      trajectory,
      featPlaceName.value!,
      featPlaceCode.value!,
      sportId,
    );
    if (result == null) {
      return null;
    }
    final distance = result.mileage * 1000;

    _distance.value = distance.toDouble(); // 更新距离
    final remainDistance =
        featUserConfig.value.targetDistance - _distance.value;

    if (_mode.value == .auto && remainDistance < 0) {
      _stopSport();
    }

    return UploadCallbackRsult(
      distance: distance.toDouble(),
      time: result.timeConsuming,
      forbiddenCount: result.expiredCountInForbiddenArea,
    );
  }

  Future<void> sportRetryUploadCallback(
    String sportId,
    List<TrajPoint> points,
  ) async {
    await _apiClient.retryUploadPoints(
      points,
      featPlaceName.value!,
      featPlaceCode.value!,
      sportId,
    );
  }

  Widget _buildInfoField(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required void Function()? onLongPress,
  }) {
    final colors = context.theme.colors;
    return FItem(
      title: Text(
        title,
        style: TextStyle(color: colors.mutedForeground, fontSize: 14),
      ),
      details: Text(
        value,
        style: TextStyle(color: colors.foreground, fontSize: 14),
        maxLines: 3,
        textAlign: .end,
      ),
      prefix: Icon(icon),
      onLongPress: onLongPress,
    );
  }
}
