import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/service/lbs/location.dart';

/// 地图选点页面
///
/// 展示地图，拖动地图使目标位置对准屏幕中心标记，点击"确认位置"后返回该坐标。
class MapPickerPage extends StatefulWidget {
  /// 初始坐标（可选），若不传则使用默认位置（重庆）
  final Coordinate? initialCoordinate;

  /// 初始缩放级别，默认为 16
  final int initialZoomLevel;

  const MapPickerPage({
    super.key,
    this.initialCoordinate,
    this.initialZoomLevel = 16,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  BMFMapController? _mapController;
  late BMFMapOptions _mapOptions;
  BMFCoordinate? _currentCenter;
  bool _locationServiceStarted = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialCoordinate;
    _currentCenter = BMFCoordinate(
      init?.lat ?? 29.53282,
      init?.lng ?? 106.60756,
    );
    _mapOptions = BMFMapOptions(
      center: _currentCenter!,
      zoomLevel: widget.initialZoomLevel,
      buildingsEnabled: true,
      showZoomControl: true,
      gesturesEnabled: true,
    );
  }

  @override
  void dispose() {
    if (_locationServiceStarted) {
      stopLocationService();
    }
    _mapController = null;
    super.dispose();
  }

  void _onMapStatusChanged() {
    _mapController?.getMapStatus().then((status) {
      if (mounted && status != null && status.targetGeoPt != null) {
        setState(() {
          _currentCenter = status.targetGeoPt;
        });
      }
    });
  }

  Future<void> _onConfirm() async {
    final controller = _mapController;
    if (controller == null) return;

    final status = await controller.getMapStatus();
    if (!mounted || status == null || status.targetGeoPt == null) return;

    final center = status.targetGeoPt!;
    Navigator.of(context).pop(
      Coordinate(lat: center.latitude, lng: center.longitude),
    );
  }

  void _locateToCurrent() {
    if (_mapController == null) return;
    _locationServiceStarted = true;
    startLocationService(LocationServiceOptions());
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _mapController == null) return;
      final lat = rawLat.value;
      final lng = rawLng.value;
      if (lat != 0 && lng != 0) {
        _mapController?.setCenterCoordinate(
          BMFCoordinate(lat, lng),
          true,
          animateDurationMs: 500,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏（不在 Stack 内，避免约束异常）
            FHeader.nested(
              title: Text(t.title.pick_location),
              prefixes: [
                FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
              ],
            ),
            // 地图层 + 浮层
            Expanded(
              child: Stack(
                children: [
                  // 地图
                  Positioned.fill(
                    child: BMFMapWidget(
                      mapOptions: _mapOptions,
                      onBMFMapCreated: (controller) {
                        _mapController = controller;
                        controller.setMapStatusDidChangedCallback(
                          callback: _onMapStatusChanged,
                        );
                      },
                    ),
                  ),

                  // 中心图钉标记
                  Center(
                    child: IgnorePointer(
                      child: FractionalTranslation(
                        translation: const Offset(0, -0.5),
                        child: Image.asset(
                          'assets/icon/icon_pin.png',
                          width: 32,
                        ),
                      ),
                    ),
                  ),

                  // 坐标显示卡片（左下）
                  Positioned(
                    bottom: 72,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background.withAlpha(220),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(32),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Icon(
                            LucideIcons.crosshair,
                            size: 14,
                            color: colors.primary,
                          ),
                          Text(
                            _currentCenter != null
                                ? '${_currentCenter!.latitude.toStringAsFixed(6)},${_currentCenter!.longitude.toStringAsFixed(6)}'
                                : '--, --',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: colors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 定位按钮
                  Positioned(
                    bottom: 72,
                    right: 24,
                    child: FButton.icon(
                      variant: .outline,
                      size: .sm,
                      onPress: _locateToCurrent,
                      child: const Icon(LucideIcons.locateFixed, size: 20),
                    ),
                  ),

                  // 确认按钮
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: FButton(
                      variant: .primary,
                      size: .sm,
                      onPress: _onConfirm,
                      prefix: const Icon(LucideIcons.mapPinCheck),
                      child: Text(t.action.confirm_location),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}