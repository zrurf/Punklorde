import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/model/sport.dart';

class InnerMapService {
  // 地图控制器
  late BMFMapController _mapController;

  final Map<String, BMFPolygon> _fencePolygons = {};
  final Map<String, BMFPolygon> _forbiddenPolygons = {};

  BMFMarker? _previewStartMarker;
  BMFMarker? _playMarker;
  BMFPolyline? _previewLine;
  BMFPolyline? _playLine;
  BMFPolyline? _originLine;

  BMFMapController get mapController => _mapController;

  void init(BMFMapController controller) {
    _mapController = controller;
  }

  void stop() {
    _mapController.cleanAllMarkers();
    _mapController.clearOverlays();

    _fencePolygons.clear();
    _forbiddenPolygons.clear();
  }

  // 移动地图
  void moveTo(double lat, double lng) {
    _mapController.setCenterCoordinate(BMFCoordinate(lat, lng), true);
  }

  // 缩放地图
  void scala(double zoom) {
    _mapController.setZoomTo(zoom);
  }

  // 绘制预览路径
  void drawPreviewPath(List<Coordinate> points) {
    clearPreviewPath();

    final path = points.map((v) => BMFCoordinate(v.lat, v.lng)).toList();
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
    _mapController.addPolyline(_previewLine!);
    _mapController.addMarker(_previewStartMarker!);
    _mapController.setCenterCoordinate(path.first, true);
  }

  // 清除预览路径
  void clearPreviewPath() {
    if (_previewLine != null) {
      _mapController.removeOverlay(_previewLine!.id);
      _previewLine = null;
    }
    if (_previewStartMarker != null) {
      _mapController.removeMarker(_previewStartMarker!);
      _previewStartMarker = null;
    }
  }

  // 绘制历史轨迹（续跑时显示原跑步路线，深绿色）
  void drawOriginTrack(List<Coordinate> points) {
    clearOriginTrack();
    if (points.length < 2) return;

    _originLine = BMFPolyline(
      coordinates: points.map((v) => BMFCoordinate(v.lat, v.lng)).toList(),
      width: 8,
      dottedLine: false,
      colors: [const Color(0xFF2E7D32)],
      lineCapType: BMFLineCapType.LineCapButt,
      lineJoinType: BMFLineJoinType.LineJoinRound,
    );
    _mapController.addPolyline(_originLine!);
  }

  // 清除历史轨迹
  void clearOriginTrack() {
    if (_originLine != null) {
      _mapController.removeOverlay(_originLine!.id);
      _originLine = null;
    }
  }

  // 绘制运动轨迹
  void initPlayPath(Coordinate pos, bool showMarker) {
    final coord = BMFCoordinate(pos.lat, pos.lng);
    _playLine = BMFPolyline(
      coordinates: [coord, coord],
      width: 8,
      dottedLine: false,
      colors: [Colors.blue],
      lineCapType: BMFLineCapType.LineCapButt,
      lineJoinType: BMFLineJoinType.LineJoinRound,
    );

    _mapController.addPolyline(_playLine!);

    if (showMarker) {
      _playMarker = BMFMarker.icon(
        position: coord,
        icon: "assets/icon/icon_blue_point.png",
        identifier: "play_marker",
        scaleX: 1.5,
        scaleY: 1.5,
        anchorX: 0.5,
        anchorY: 0.5,
      );
      _mapController.addMarker(_playMarker!);
    }
  }

  // 更新运动轨迹
  void updatePlayPath(Coordinate pos) {
    // 定位晚于开始到达时，懒初始化轨迹
    if (_playLine == null) {
      initPlayPath(pos, false);
      return;
    }
    final coord = BMFCoordinate(pos.lat, pos.lng);
    _playLine?.updateCoordinates(_playLine!.coordinates + [coord]);
    _playMarker?.updatePosition(coord);
  }

  // 清空运动轨迹
  void clearPlayPath() {
    if (_playLine != null) {
      _mapController.removeOverlay(_playLine!.id);
      _playLine = null;
    }
    if (_playMarker != null) {
      _mapController.removeMarker(_playMarker!);
      _playMarker = null;
    }
  }

  // 绘制运动场区域（对齐小程序 showQuYu：dzwl 电子围栏绿色，其余禁区红色）
  void drawFences(List<SportArea> areas) {
    clearFences();

    const fenceColor = Color(0xCC28E642); // dzwl 电子围栏
    const forbiddenColor = Color(0xCCFF2B29); // 禁跑区/其他

    for (final (i, area) in areas.indexed) {
      if (area.areaPointList.length < 3) continue;
      final coords = area.areaPointList
          .map((p) => BMFCoordinate(p.lat, p.lng))
          .toList();
      final isFence = area.areaFuncCode == 'dzwl';
      final color = isFence ? fenceColor : forbiddenColor;

      final polygon = BMFPolygon(
        coordinates: coords,
        width: 2,
        strokeColor: color,
        fillColor: color.withValues(alpha: 0.15),
        zIndex: 1,
      );

      if (isFence) {
        _fencePolygons['$i'] = polygon;
      } else {
        _forbiddenPolygons['$i'] = polygon;
      }
      _mapController.addPolygon(polygon);
    }
  }

  // 清除运动场区域
  void clearFences() {
    for (final p in _fencePolygons.values) {
      _mapController.removeOverlay(p.id);
    }
    for (final p in _forbiddenPolygons.values) {
      _mapController.removeOverlay(p.id);
    }
    _fencePolygons.clear();
    _forbiddenPolygons.clear();
  }
}
