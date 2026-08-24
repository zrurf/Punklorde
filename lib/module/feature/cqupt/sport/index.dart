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
import 'package:punklorde/module/feature/cqupt/sport/api/model/sport.dart';
import 'package:punklorde/module/feature/cqupt/sport/constant.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/resource/resource.dart';
import 'package:punklorde/module/feature/cqupt/sport/service/map.dart';
import 'package:punklorde/utils/etc/fdialog.dart';
import 'package:punklorde/module/feature/cqupt/sport/service/sport.dart';
import 'package:punklorde/module/feature/cqupt/sport/service/track_store.dart';
import 'package:punklorde/module/feature/cqupt/sport/utils/time.dart';
import 'package:punklorde/module/feature/cqupt/sport/view/widgets/config_pannel.dart';
import 'package:punklorde/module/feature/cqupt/sport/view/widgets/resume_panel.dart';
import 'package:punklorde/module/feature/cqupt/sport/view/widgets/user_panel.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/sport.dart';
import 'package:punklorde/module/service/lbs/location.dart';
import 'package:punklorde/src/rust/services/motion_sim/model.dart';
import 'package:punklorde/utils/notification.dart';
import 'package:punklorde/utils/lbs/distance.dart';
import 'package:punklorde/utils/permission.dart';
import 'package:signals/signals_flutter.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

/// 续跑上下文
class _ResumeContext {
  final String sportId;
  final String placeCode;
  final String placeName;

  /// 继承的里程（米）与时长（毫秒）
  final double initialDistance;
  final int initialElapsedTimeMs;

  /// 从最近点开始的续跑路线
  final Trajectory trajectory;

  const _ResumeContext({
    required this.sportId,
    required this.placeCode,
    required this.placeName,
    required this.initialDistance,
    required this.initialElapsedTimeMs,
    required this.trajectory,
  });
}

class FeatCquptSportView extends SignalStatefulWidget {
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

  final Set<String> _faceRecordCache = {}; // 人脸记录缓存
  bool _faceRecordUpdateLock = false;

  // 续跑状态
  String? _pendingResumeSportId; // 待恢复的运动编号

  // 当前运动使用的场地（自动跑来自预设，自己跑来自定位匹配）
  String _curPlaceCode = '';
  String _curPlaceName = '';

  // 自己跑开始前定位匹配到的场地缓存
  String? _resolvedPlaceCode;
  String? _resolvedPlaceName;

  // 定时器
  Timer? _updateTimer;
  Timer? _faceRecordTimer;

  @override
  void initState() {
    // 申请权限
    checkAndRequestPermission(.location);
    checkAndRequestPermission(.notice);
    _mapService = InnerMapService();
    _sportService = InnerSportService();

    final user = authManager.getPrimaryAuthByPlatform(platCquptSport.id);
    if (user != null && user.isValid()) {
      // _changeUser 内部会拉取进行中记录
      _changeUser(user);
    } else {
      fetchResumableRecords();
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
    _faceRecordTimer?.cancel();
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
      canPop: !_isRunning.value,
      onPopInvokedWithResult: (didPop, result) async {
        if (_isRunning.value) {
          showFToast(
            context: context,
            variant: .destructive,
            alignment: .topCenter,
            title: Text(t.submodule.cqupt_sport.tip_need_stop),
            duration: const Duration(seconds: 3),
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
              visible: !_isRunning.value,
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
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    FButton.icon(
                      variant: .outline,
                      size: .sm,
                      onPress: () {
                        context.push("/feat/cqupt/sport/about");
                      },
                      child: const Icon(LucideIcons.info),
                    ),
                  ],
                ),
              ),
            ),
            // 跑步状态栏
            Visibility(
              visible: _isRunning.value,
              child: Positioned(
                left: 12,
                right: 12,
                top: 12,
                height: 120,
                child: Container(
                  // 复刻迁移前 FCard.raw 的自定义暗色样式（forui 0.24+ 移除该 API）
                  decoration: BoxDecoration(
                    color: const Color(0xE01d1d1f),
                    border: Border.all(
                      color: const Color(0xF01d1d1f),
                      width: 1,
                    ),
                    borderRadius: .circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xE01d1d1f),
                        blurRadius: 2,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Builder(
                      builder: (context) {
                        // 轨迹录制为纯本地模式：无目标/剩余/进度，距离由本地 Haversine 累计
                        final isRecording = _mode.value == .record;

                        return Column(
                          children: [
                            // 顶部数据区域（每秒变化的运动数据，SignalBuilder 局部重建）
                            Expanded(
                              child: SignalBuilder(
                                builder: (context) => Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 运动时间
                                    _buildStatColumn(
                                      context,
                                      mainValue: formatDuration(
                                        _duration.value,
                                      ),
                                      mainLabel:
                                          t.submodule.cqupt_sport.elapsed_time,
                                      subValue: (isRecording)
                                          ? '${_sportService?.recordPoints.length ?? 0} ${t.submodule.cqupt_sport.track_points_unit}'
                                          : '${t.submodule.cqupt_sport.remain_time} ${formatDuration(_remainTime.value)}',
                                      alignment: CrossAxisAlignment.center,
                                    ),

                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),

                                    // 运动距离
                                    _buildStatColumn(
                                      context,
                                      mainValue: "${_distance.value.round()}m",
                                      mainLabel:
                                          t.submodule.cqupt_sport.distance,
                                      subValue: (isRecording)
                                          ? ''
                                          : '${t.submodule.cqupt_sport.target_distance} ${featUserConfig.value.targetDistance.round()}m',
                                      alignment: CrossAxisAlignment.center,
                                    ),

                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),

                                    // 速度/配速
                                    _buildStatColumn(
                                      context,
                                      mainValue: formatPace(_speed.value),
                                      mainLabel: t.submodule.cqupt_sport.pace,
                                      subValue:
                                          '${t.submodule.cqupt_sport.speed} ${_speed.value.toStringAsFixed(2)}m/s',
                                      alignment: CrossAxisAlignment.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 底部进度条（仅自动跑/自己跑有目标概念）
                            if (!isRecording)
                              SignalBuilder(
                                builder: (context) =>
                                    _buildProgressBar(context),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 续跑提示横幅
            SignalBuilder(
              builder: (context) {
                final hasResumable =
                    !_isRunning.value && featResumableRecords.value.isNotEmpty;
                return Visibility(
                  visible: hasResumable,
                  child: Positioned(
                    left: 12,
                    right: 12,
                    bottom: 116,
                    child: FButton(
                      variant: .outline,
                      size: .sm,
                      prefix: Icon(
                        LucideIcons.flagTriangleRight,
                        color: colors.primary,
                      ),
                      suffix: const Icon(LucideIcons.chevronRight),
                      onPress: _showResumePanel,
                      child: Text(t.submodule.cqupt_sport.resume_found_hint),
                    ),
                  ),
                );
              },
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
                                showFToast(
                                  context: context,
                                  variant: .destructive,
                                  alignment: .topCenter,
                                  title: Text(
                                    t.submodule.cqupt_sport.tip_need_stop,
                                  ),
                                  icon: const Icon(LucideIcons.circleX),
                                  duration: const Duration(seconds: 3),
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
                                showFToast(
                                  context: context,
                                  variant: .destructive,
                                  alignment: .topCenter,
                                  title: Text(
                                    t.submodule.cqupt_sport.tip_need_stop,
                                  ),
                                  icon: const Icon(LucideIcons.circleX),
                                  duration: const Duration(seconds: 3),
                                );
                                return;
                              }
                              showFSheet(
                                context: context,
                                builder: (sheetContext) => ConfigPanel(
                                  onSelectMotionProfile: () {
                                    // 虚拟路径预览仅为自动跑服务
                                    if (_mode.value != .auto ||
                                        _isRunning.value) {
                                      return;
                                    }
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
                                  currentUser: featCredential.value,
                                  onSelect: (AuthCredential? credential) {
                                    if (_isRunning.value) {
                                      showFToast(
                                        context: context,
                                        variant: .destructive,
                                        alignment: .topCenter,
                                        title: Text(
                                          t.submodule.cqupt_sport.tip_need_stop,
                                        ),
                                        icon: const Icon(LucideIcons.circleX),
                                        duration: const Duration(seconds: 3),
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
    final distance = _distance.value;
    final target = featUserConfig.value.targetDistance;
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
    final isRunning = _isRunning.value;
    final mode = _mode.value;
    // 配置信息仅为自动跑服务
    final showConfigFields =
        !isRunning && mode == .auto || isRunning && mode != .record;

    return GestureDetector(
      onTap: () {
        if (!isRunning && mode == .normal) {
          // 自己跑：先定位匹配场地，确认框显示跑步地点（与官方一致）
          _confirmNormalStart();
          return;
        }
        showFDialog(
          context: context,
          builder: (context, style, animation) {
            return punklordeDialog(
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
                        ? (mode == .record)
                              ? t.submodule.cqupt_sport.record_stop_tip
                              : t.submodule.cqupt_sport.stop_run_tip
                        : (mode != .auto)
                        ? modeNames[mode] ?? ''
                        : t.submodule.cqupt_sport.start_run_tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                    textAlign: .center,
                  ),

                  if (showConfigFields)
                    _buildInfoField(
                      context,
                      title: t.title.user,
                      value: featCredential.value?.name ?? "",
                      icon: LucideIcons.userRound,
                      onLongPress: () {},
                    ),

                  if (showConfigFields)
                    _buildInfoField(
                      context,
                      title: t.submodule.cqupt_sport.distance,
                      value: (isRunning)
                          ? '${_distance.value.toString()} / ${featUserConfig.value.targetDistance.toString()} m'
                          : '${featUserConfig.value.targetDistance.toString()} m',
                      icon: LucideIcons.lineSquiggle,
                      onLongPress: () {},
                    ),

                  if (showConfigFields)
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
                      _stopSport(askKeepRecord: true);
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
      LocationServiceOptions(purpose: .sport, interval: 1000, coorType: .gcj02),
    ); // 启用定位服务
    if (!result) {
      stopHeadingService();
      stopLocationService();
      if (context != null && context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          alignment: .topCenter,
          title: Text(t.notice.location_service_failed),
          description: Text(t.notice.location_service_failed_msg),
          icon: const Icon(LucideIcons.circleX),
          duration: const Duration(seconds: 3),
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

    // 绘制电子围栏与禁区（对齐官方 showQuYu）
    _apiClient.getSportAreas().then((areas) {
      if (areas.isNotEmpty) {
        _mapService?.drawFences(areas);
      }
    });
  }

  // 切换用户
  void _changeUser(AuthCredential? cred) {
    featCredential.value = cred;

    initFaceRecordNotice();
    fetchResumableRecords();
  }

  // 拉取进行中的运动记录（已开始未结束，可续跑）
  Future<void> fetchResumableRecords() async {
    if (featCredential.value == null) {
      featResumableRecords.value = [];
      return;
    }
    // 限流：仅拉取第一页最新 10 条（client 内再过滤今天未完成的记录）
    final list = await _apiClient.getWxSportRecords(1, 10);
    // 排除当前会话正在使用的编号
    featResumableRecords.value = list
        .where((v) => v.sportRecordNo != _pendingResumeSportId)
        .toList();
  }

  // 自己跑：定位匹配场地后确认开始
  Future<void> _confirmNormalStart() async {
    final context = widgetKey.currentContext;
    if (context == null || !context.mounted) return;
    final colors = context.theme.colors;

    if (featCredential.value == null) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.notice.unselected_user),
        icon: const Icon(LucideIcons.circleX),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    _resolvedPlaceCode = null;
    _resolvedPlaceName = null;
    final place = await _resolvePlaceByLocation();
    if (!context.mounted) return;
    if (place == null || (place.$1.isEmpty && place.$2.isEmpty)) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.submodule.cqupt_sport.not_in_playground),
        icon: const Icon(LucideIcons.circleX),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    _resolvedPlaceCode = place.$1;
    _resolvedPlaceName = place.$2;

    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) {
        return punklordeDialog(
          style: style,
          animation: animation,
          title: Text(t.submodule.cqupt_sport.start_run),
          body: Column(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              Text(
                t.submodule.cqupt_sport.normal_start_confirm(place: place.$2),
                textAlign: .center,
                style: TextStyle(fontSize: 14, color: colors.mutedForeground),
              ),
              _buildInfoField(
                dialogContext,
                title: t.title.user,
                value: featCredential.value?.name ?? "",
                icon: LucideIcons.userRound,
                onLongPress: () {},
              ),
            ],
          ),
          actions: [
            FButton(
              size: .xs,
              onPress: () {
                Navigator.of(dialogContext).pop();
                _startSport();
              },
              child: Text(t.notice.confirm),
            ),
            FButton(
              onPress: () {
                Navigator.of(dialogContext).pop();
              },
              size: .xs,
              variant: .secondary,
              child: Text(t.notice.cancel),
            ),
          ],
        );
      },
    );
  }

  // 打开续跑面板
  void _showResumePanel() {
    final context = widgetKey.currentContext;
    if (context == null || !context.mounted) return;

    if (_isRunning.value) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.submodule.cqupt_sport.tip_need_stop),
        icon: const Icon(LucideIcons.circleX),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (featCredential.value == null) {
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        title: Text(t.notice.unselected_user),
        icon: const Icon(LucideIcons.circleX),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    showFSheet(
      context: context,
      side: .btt,
      builder: (sheetContext) => ResumePanel(
        records: featResumableRecords.value,
        onConfirm: (record, route, info) {
          Navigator.of(sheetContext).pop();
          _confirmResume(record, route, info);
        },
      ),
    );
  }

  // 续跑确认弹窗
  void _confirmResume(
    WxSportRecord record,
    VirtualPath route,
    SportInfoResult info,
  ) {
    final context = widgetKey.currentContext;
    if (context == null || !context.mounted) return;

    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) {
        return punklordeDialog(
          style: style,
          animation: animation,
          title: Text(t.submodule.cqupt_sport.resume_confirm_title),
          body: Column(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              _buildInfoField(
                dialogContext,
                title: t.submodule.cqupt_sport.record_place,
                value: record.placeName ?? '-',
                icon: LucideIcons.mapPin,
                onLongPress: () {},
              ),
              _buildInfoField(
                dialogContext,
                title: t.submodule.cqupt_sport.distance,
                value:
                    '${(info.mileage * 1000).round()} m / ${formatDuration(Duration(seconds: info.timeConsuming.round()))}',
                icon: LucideIcons.lineSquiggle,
                onLongPress: () {},
              ),
              _buildInfoField(
                dialogContext,
                title: t.submodule.cqupt_sport.virtual_route,
                value: route.name,
                icon: LucideIcons.route,
                onLongPress: () {},
              ),
            ],
          ),
          actions: [
            FButton(
              size: .xs,
              onPress: () {
                Navigator.of(dialogContext).pop();
                _performResume(record, route, info);
              },
              child: Text(t.notice.confirm),
            ),
            FButton(
              onPress: () {
                Navigator.of(dialogContext).pop();
              },
              size: .xs,
              variant: .secondary,
              child: Text(t.notice.cancel),
            ),
          ],
        );
      },
    );
  }

  // 执行续跑：继承原里程与时间，从选定路线的最近点开始
  Future<void> _performResume(
    WxSportRecord record,
    VirtualPath route,
    SportInfoResult info,
  ) async {
    final context = widgetKey.currentContext;

    final ok = await _apiClient.continueSport(record.sportRecordNo);
    if (!ok) {
      if (context != null && context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          alignment: .topCenter,
          title: Text(t.submodule.cqupt_sport.resume_failed),
          icon: const Icon(LucideIcons.circleX),
          duration: const Duration(seconds: 3),
        );
      }
      fetchResumableRecords();
      return;
    }

    _mode.value = .auto; // 续跑固定使用模拟器

    // 在地图上绘制原跑步轨迹（深绿色）
    _mapService?.drawOriginTrack(
      info.points
          .map((p) => Coordinate(lat: p.latitude, lng: p.longitude))
          .toList(),
    );

    // 继承真实里程与时间
    final initialDistance = (info.mileage * 1000).roundToDouble();
    final initialElapsedTimeMs = (info.timeConsuming * 1000).round();

    // 参考位置：原轨迹最后一点，缺失时退回当前定位
    Coordinate? refPoint;
    final originPoints = info.points;
    if (originPoints.isNotEmpty) {
      refPoint = Coordinate(
        lat: originPoints.last.latitude,
        lng: originPoints.last.longitude,
      );
    } else if (rawLat.value != 0 || rawLng.value != 0) {
      refPoint = Coordinate(lat: rawLat.value, lng: rawLng.value);
    }

    // 在路线上寻找距参考位置最近的点作为续跑起点，并旋转路线使其成为首点
    var nearestIdx = 0;
    if (refPoint != null) {
      var best = double.infinity;
      for (final (i, p) in route.points.indexed) {
        final d = haversineDistance(refPoint.lat, refPoint.lng, p.lat, p.lng);
        if (d < best) {
          best = d;
          nearestIdx = i;
        }
      }
    }
    final rotatedPoints = [
      ...route.points.sublist(nearestIdx),
      ...route.points.take(nearestIdx),
    ];

    final started = await _startSport(
      resume: _ResumeContext(
        sportId: record.sportRecordNo,
        placeCode: record.placeCode ?? '',
        placeName: record.placeName ?? '',
        initialDistance: initialDistance,
        initialElapsedTimeMs: initialElapsedTimeMs,
        trajectory: Trajectory(
          id: route.id,
          name: route.name,
          points: rotatedPoints
              .map((p) => GeoPoint(latitude: p.lat, longitude: p.lng))
              .toList(),
        ),
      ),
    );

    if (!started) {
      _pendingResumeSportId = null;
      return;
    }

    // 从候选列表中移除已恢复的记录
    featResumableRecords.value = featResumableRecords.value
        .where((v) => v.sportRecordNo != record.sportRecordNo)
        .toList();
  }

  Future<bool> _startSport({_ResumeContext? resume}) async {
    if (_isRunning.value) {
      return false;
    }
    final context = widgetKey.currentContext;
    final mode = _mode.value;

    try {
      // 凭据要求：自动跑/自己跑需要，轨迹录制为纯本地模式
      if (mode != .record && featCredential.value == null) {
        if (context != null && context.mounted) {
          showFToast(
            context: context,
            variant: .destructive,
            alignment: .topCenter,
            title: Text(t.notice.unselected_user),
            icon: const Icon(LucideIcons.circleX),
            duration: const Duration(seconds: 3),
          );
        }
        return false;
      }

      // 预设资源仅为自动跑服务；自己跑通过定位匹配场地，轨迹录制无需场地
      if (resume == null && mode == .auto) {
        final hasPreset =
            featPlaceCode.value != null &&
            featPlaceName.value != null &&
            featMotionProfile.value != null &&
            featVirtualPaths.value != null;
        if (!hasPreset) {
          if (context != null && context.mounted) {
            showFToast(
              context: context,
              variant: .destructive,
              alignment: .topCenter,
              title: Text(t.notice.wait_reource_load),
              icon: const Icon(LucideIcons.circleX),
              duration: const Duration(seconds: 3),
            );
          }
          return false;
        }
      }

      if ((mode == .normal || mode == .record) &&
          !await checkAndRequestPermission(.location)) {
        return false;
      }

      // 确定本次运动的场地信息
      switch (mode) {
        case .auto when resume == null:
          _curPlaceCode = featPlaceCode.value ?? '';
          _curPlaceName = featPlaceName.value ?? '';
        case .normal:
          // 优先使用开始确认时定位匹配的场地缓存
          final cachedCode = _resolvedPlaceCode;
          final cachedName = _resolvedPlaceName;
          _resolvedPlaceCode = null;
          _resolvedPlaceName = null;
          final (code, name) = (cachedCode != null && cachedName != null)
              ? (cachedCode, cachedName)
              : await _resolvePlaceByLocation() ?? ('', '');
          if (code.isEmpty && name.isEmpty) {
            if (context != null && context.mounted) {
              showFToast(
                context: context,
                variant: .destructive,
                alignment: .topCenter,
                title: Text(t.submodule.cqupt_sport.not_in_playground),
                icon: const Icon(LucideIcons.circleX),
                duration: const Duration(seconds: 3),
              );
            }
            return false;
          }
          _curPlaceCode = code;
          _curPlaceName = name;
        case .record:
          _curPlaceCode = '';
          _curPlaceName = '';
        default:
          _curPlaceCode = resume?.placeCode ?? '';
          _curPlaceName = resume?.placeName ?? '';
      }

      // 续跑时使用选定的虚拟路线（从最近点开始），否则使用运动预设中的全部路线
      final List<Trajectory> trajectories = (resume != null)
          ? [resume.trajectory]
          : (featMotionProfile.value?.data?.paths
                    .map((v) {
                      final vp = featVirtualPaths.value?[v];
                      if (vp == null) return null;
                      return Trajectory(
                        id: vp.id,
                        name: vp.name,
                        points: vp.points
                            .map(
                              (v1) =>
                                  GeoPoint(latitude: v1.lat, longitude: v1.lng),
                            )
                            .toList(),
                      );
                    })
                    .nonNulls
                    .toList() ??
                []);

      if (resume != null) {
        _pendingResumeSportId = resume.sportId;
        // 续跑路线预览（传入旋转后的路线，起点标记即落在续跑起跑点）
        _mapService?.clearPreviewPath();
        _mapService?.drawPreviewPath(
          resume.trajectory.points
              .map((p) => Coordinate(lat: p.latitude, lng: p.longitude))
              .toList(),
        );
      } else if (mode == .normal || mode == .record) {
        // 自己跑/轨迹录制无路线概念，清除路线预览与历史轨迹
        _mapService?.clearPreviewPath();
        _mapService?.clearOriginTrack();
      }

      final ok =
          await _sportService?.start(
            InnerSportServiceConfig(
              mode: mode,
              placeCode: _curPlaceCode,
              placeName: _curPlaceName,
              initialDistance: resume?.initialDistance ?? 0,
              initialElapsedTimeMs: resume?.initialElapsedTimeMs ?? 0,
              startCaallback: sportStartCallback,
              stopCallback: sportStopCallback,
              recordCallback: sportRecordCallback,
              uploadCallback: sportUploadCallback,
              retryUploadCallback: sportRetryUploadCallback,
              autoRunConfig: AutoRunningConfig(
                placeCode: _curPlaceCode,
                placeName: _curPlaceName,
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
                  speedJitterAmplitude:
                      featUserConfig.value.speedJitterAmplitude,
                  bearingJitterAmplitude: 5,
                  accelerometerJitterAmplitude: 0.4,
                  gyroscopeJitterAmplitude: 0,
                  jitterFrequencyScale: 0.12,
                  trajectoryMode: (trajectories.length != 1)
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
                trajectories: trajectories,
              ),
            ),
          ) ??
          false;
      if (!ok) {
        _pendingResumeSportId = null;
        return false;
      }
      WakelockPlus.enable();
      _isRunning.value = true;
      showNotification(
        t.submodule.cqupt_sport.start_run_notice,
        t.submodule.cqupt_sport.start_run_notice_hint,
        id: noticeChannelId,
        channelId: noticeChannelStrId,
        channelName: noticeChannelName,
      );

      _duration.value = Duration(
        milliseconds: resume?.initialElapsedTimeMs ?? 0,
      );
      // 复位运动数据（续跑继承原里程，其余从零开始）
      _distance.value = resume?.initialDistance ?? 0;
      _speed.value = 0;
      _remainTime.value = Duration.zero;
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _duration.value += const Duration(seconds: 1);
      });
      _mapService?.clearPlayPath();

      // 地图轨迹起点：续跑用旋转后路线首点，自动跑用预设路线首点，其余跟随定位（懒初始化）
      Coordinate? startPoint;
      if (resume != null) {
        final p = resume.trajectory.points.first;
        startPoint = Coordinate(lat: p.latitude, lng: p.longitude);
      } else if (mode == .auto) {
        final vpPoint = featVirtualPaths
            .value?[featMotionProfile.value?.data?.paths.first ?? '']
            ?.points
            .firstOrNull;
        startPoint = (vpPoint == null)
            ? null
            : Coordinate(lat: vpPoint.lat, lng: vpPoint.lng);
      } else {
        startPoint = (rawLat.value != 0 || rawLng.value != 0)
            ? Coordinate(lat: rawLat.value, lng: rawLng.value)
            : null;
      }
      if (startPoint != null) {
        _mapService?.initPlayPath(startPoint, mode == .auto || resume != null);
        _mapService?.moveTo(startPoint.lat, startPoint.lng);
        _mapService?.scala(19);
      }
      return true;
    } catch (_) {
      _pendingResumeSportId = null;
      // 异常发生在启动成功之后时，强制停止以保持状态一致
      if (_sportService?.isRunning ?? false) {
        await _sportService?.stop();
      }
      _isRunning.value = false;
      if (context != null && context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          alignment: .topCenter,
          title: Text(t.notice.sport_start_failed),
          icon: const Icon(LucideIcons.circleX),
          duration: const Duration(seconds: 3),
        );
      }
      return false;
    }
  }

  // 通过定位匹配运动场区域（与官方小程序 whereAmI 一致）
  Future<(String, String)?> _resolvePlaceByLocation() async {
    final lat = rawLat.value;
    final lng = rawLng.value;
    if (lat == 0 && lng == 0) return null;

    final areas = await _apiClient.getSportAreas();
    for (final area in areas) {
      // 仅跑道区域可作为跑步场地（官方 funcode: dzwl）
      if (area.areaFuncCode != null && area.areaFuncCode != 'dzwl') continue;
      if (_isPointInPolygon(lat, lng, area.areaPointList)) {
        return (area.placeCode ?? '', area.placeName ?? '');
      }
    }
    return null;
  }

  // 射线法判断点是否在多边形内（移植自官方 IsPtInPoly）
  bool _isPointInPolygon(double lat, double lng, List<Coordinate> pts) {
    final n = pts.length;
    if (n < 3) return false;

    var crossings = 0;
    for (var i = 0; i < n; i++) {
      final sLat = pts[i].lat;
      final sLng = pts[i].lng;
      final eLat = pts[(i + 1) % n].lat;
      final eLng = pts[(i + 1) % n].lng;
      if ((sLat > lat) != (eLat > lat)) {
        final crossLng = sLng + (eLng - sLng) * (lat - sLat) / (eLat - sLat);
        if (crossLng < lng) crossings++;
      }
    }
    return crossings.isOdd;
  }

  Future<void> _stopSport({bool askKeepRecord = false}) async {
    final wasRunning = _isRunning.value;
    final wasRecording = _mode.value == .record;
    final recordedPoints = List<TrajPoint>.from(
      _sportService?.recordPoints ?? const [],
    );
    await _sportService?.stop();
    _updateTimer?.cancel();
    _updateTimer = null;
    WakelockPlus.disable();
    _isRunning.value = false;

    _pendingResumeSportId = null;
    // 结束后清理路线类 overlay 并刷新进行中列表（正常结束的记录不会再出现）
    if (wasRunning) {
      _mapService?.clearPreviewPath();
      _mapService?.clearOriginTrack();
      fetchResumableRecords();
    }

    if (!askKeepRecord || !wasRecording) return;
    await _offerKeepRecordedTrack(recordedPoints);
  }

  // 录制结束后询问是否保留轨迹
  Future<void> _offerKeepRecordedTrack(List<TrajPoint> points) async {
    final context = widgetKey.currentContext;
    if (context == null || !context.mounted) return;

    if (points.length < 2) {
      showFToast(
        context: context,
        alignment: .topCenter,
        title: Text(t.submodule.cqupt_sport.track_too_few_points),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) {
        return punklordeDialog(
          style: style,
          animation: animation,
          title: Text(t.submodule.cqupt_sport.record_keep_title),
          body: Text(
            t.submodule.cqupt_sport.record_keep_tip(count: points.length),
          ),
          actions: [
            FButton(
              size: .xs,
              onPress: () async {
                Navigator.of(dialogContext).pop();
                final now = DateTime.now();
                final vp = VirtualPath(
                  id: generateRecordedTrackId(now),
                  version: 1,
                  name:
                      '${t.submodule.cqupt_sport.record_default_track_name} ${formatDate(now)}',
                  coordinateType: .gcj02,
                  points: points
                      .map(
                        (p) => VirtualPathPoint(
                          lat: p.coordinate.lat,
                          lng: p.coordinate.lng,
                        ),
                      )
                      .toList(),
                );
                try {
                  await saveRecordedTrack(vp);
                  if (context.mounted) {
                    showFToast(
                      context: context,
                      alignment: .topCenter,
                      title: Text(t.submodule.cqupt_sport.track_saved),
                      duration: const Duration(seconds: 3),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    showFToast(
                      context: context,
                      variant: .destructive,
                      alignment: .topCenter,
                      title: Text(t.submodule.cqupt_sport.track_save_failed),
                      duration: const Duration(seconds: 3),
                    );
                  }
                }
              },
              child: Text(t.submodule.cqupt_sport.keep),
            ),
            FButton(
              onPress: () {
                Navigator.of(dialogContext).pop();
              },
              size: .xs,
              variant: .secondary,
              child: Text(t.submodule.cqupt_sport.discard),
            ),
          ],
        );
      },
    );
  }

  Future<String?> sportStartCallback() async {
    final context = widgetKey.currentContext;

    // 续跑：沿用原运动编号，不新建记录
    final resumeId = _pendingResumeSportId;
    if (resumeId != null) {
      return resumeId;
    }

    // 轨迹录制：纯本地，不请求服务端
    if (_mode.value == .record) {
      return "_punklorde_record";
    }

    final sportId = await _apiClient.startSport(_curPlaceName, _curPlaceCode);

    if (sportId == null) {
      // 仅提示，清理由 service.start 内部的 _stop(.error) 统一完成
      if (context != null && context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          alignment: .topCenter,
          title: Text(t.notice.sport_start_failed),
          icon: const Icon(LucideIcons.circleX),
          duration: const Duration(seconds: 3),
        );
      }
      return null;
    }
    return (_mode.value == .record) ? "_punklorde_record" : sportId;
  }

  Future<void> sportStopCallback(String sportId) async {
    // 轨迹录制为纯本地模式，不请求服务端
    if (sportId == "_punklorde_record") return;

    await _apiClient.endSport(sportId);

    showNotification(
      t.submodule.cqupt_sport.stop_run_notice,
      "",
      id: noticeChannelId,
      channelId: noticeChannelStrId,
      channelName: noticeChannelName,
    );
  }

  Future<void> sportRecordCallback(String sportId, TrajPoint point) async {
    _speed.value = _sportService?.getSpeed ?? 0; // 更新速度
    _mapService?.updatePlayPath(point.coordinate); // 添加轨迹点

    if (_mode.value == .record) {
      // 轨迹录制：不上传，距离由本地 Haversine 累计，无目标/剩余概念
      _distance.value = _sportService?.getDistance ?? 0;
      return;
    }

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
      _curPlaceName,
      _curPlaceCode,
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
      _curPlaceName,
      _curPlaceCode,
      sportId,
    );
  }

  Future<void> initFaceRecordNotice() async {
    _faceRecordUpdateLock = true;

    final list = await _apiClient.getSportFaceRecordList(DateTime.now());
    if (list != null) {
      _faceRecordCache.addAll(list.map((v) => v.recordId));
    }
    _faceRecordUpdateLock = false;

    _faceRecordTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchFaceRecordNotice();
    });
  }

  Future<void> fetchFaceRecordNotice() async {
    if (_faceRecordUpdateLock) return;
    _faceRecordUpdateLock = true;
    final list = await _apiClient.getSportFaceRecordList(DateTime.now());
    if (list != null) {
      for (final (i, v) in list.indexed) {
        if (_faceRecordCache.contains(v.recordId)) continue;
        showFaceNotice(
          noticeChannelId2 + _faceRecordCache.length + i,
          switch (v.cameraType) {
            1 => t.submodule.cqupt_sport.face_type_enter,
            2 => t.submodule.cqupt_sport.face_type_leave,
            3 => t.submodule.cqupt_sport.face_type_run,
            _ => "",
          },
          v.cameraName,
        );
        _faceRecordCache.add(v.recordId);
      }
    }
    _faceRecordUpdateLock = false;
  }

  void showFaceNotice(int id, String type, String message) {
    showNotification(
      "${t.submodule.cqupt_sport.face_notice}-$type",
      message,
      id: id,
      channelId: noticeChannelStrId,
      channelName: noticeChannelName,
      importance: 4,
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
