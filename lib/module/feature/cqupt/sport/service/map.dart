import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:punklorde/common/model/location.dart';

class InnerMapService {
  // 地图控制器
  late BMFMapController _mapController;

  final Map<String, BMFPolygon> _fencePolygons = {};
  final Map<String, BMFPolygon> _forbiddenPolygons = {};

  BMFMarker? _previewStartMarker;
  BMFMarker? _playMarker;
  BMFPolyline? _previewLine;
  BMFPolyline? _playLine;

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
    final coord = BMFCoordinate(pos.lat, pos.lng);
    _playLine?.updateCoordinates(_playLine!.coordinates + [coord]);
    _playMarker?.updatePosition(coord);
  }

  // 清空运动轨迹
  void clearPlayPath() {
    if (_playLine != null) {
      _mapController.removeOverlay(_playLine!.id);
      _previewLine = null;
    }
    if (_playMarker != null) {
      _mapController.removeMarker(_playMarker!);
      _previewStartMarker = null;
    }
  }
}
