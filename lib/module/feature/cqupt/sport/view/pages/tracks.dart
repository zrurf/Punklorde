import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/service/track_store.dart';
import 'package:punklorde/utils/etc/fdialog.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals_flutter.dart';

/// 已录制轨迹列表
class FeatSportCquptTracksView extends SignalStatefulWidget {
  const FeatSportCquptTracksView({super.key});

  @override
  State<FeatSportCquptTracksView> createState() =>
      _FeatSportCquptTracksViewState();
}

class _FeatSportCquptTracksViewState extends State<FeatSportCquptTracksView> {
  @override
  void initState() {
    super.initState();
    refreshRecordedTracks();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.submodule.cqupt_sport.recorded_tracks),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            Expanded(
              child: SignalBuilder(
                builder: (context) {
                  final tracks = featRecordedTracks.value;
                  if (tracks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: .min,
                        spacing: 8,
                        children: [
                          Icon(
                            LucideIcons.route,
                            color: colors.primary,
                            size: 32,
                          ),
                          Text(
                            t.submodule.cqupt_sport.track_empty,
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const .symmetric(horizontal: 16, vertical: 8),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) =>
                        _buildTrackCard(tracks[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(RecordedTrack entry) {
    final colors = context.theme.colors;
    final vp = entry.track;

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: FCard(
        child: Padding(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: .start,
            spacing: 6,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      vp.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: .bold,
                        color: colors.foreground,
                      ),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ),
                  FBadge(
                    variant: .secondary,
                    child: Text(
                      vp.coordinateType.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              Text(
                '${vp.points.length} ${t.submodule.cqupt_sport.track_points_unit}'
                ' · ${t.submodule.cqupt_sport.track_saved_at} ${formatDate(entry.savedAt)}',
                style: TextStyle(fontSize: 13, color: colors.mutedForeground),
              ),
              Row(
                spacing: 4,
                children: [
                  FButton.icon(
                    variant: .outline,
                    size: .xs,
                    onPress: () {
                      context.push(
                        "/feat/cqupt/sport/tracks/detail?id=${Uri.encodeComponent(vp.id)}",
                      );
                    },
                    child: const Icon(LucideIcons.map),
                  ),
                  FButton.icon(
                    variant: .outline,
                    size: .xs,
                    onPress: () => _exportTrack(vp),
                    child: const Icon(LucideIcons.share2),
                  ),
                  FButton.icon(
                    variant: .outline,
                    size: .xs,
                    onPress: () => _confirmDelete(vp),
                    child: Icon(LucideIcons.trash2, color: colors.destructive),
                  ),
                  Spacer(),
                  Text(
                    '#${vp.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 导出轨迹 JSON
  Future<void> _exportTrack(VirtualPath vp) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(const JsonEncoder.withIndent('  ').convert(vp)),
            ),
          ],
          fileNameOverrides: ['${vp.id}.path.json'],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showFToast(
        context: context,
        variant: .destructive,
        alignment: .topCenter,
        icon: const Icon(LucideIcons.circleX),
        title: Text(t.notice.share_failed),
      );
    }
  }

  // 删除确认
  void _confirmDelete(VirtualPath vp) {
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) {
        return punklordeDialog(
          style: style,
          animation: animation,
          title: Text(t.submodule.cqupt_sport.track_delete_title),
          body: Text(t.submodule.cqupt_sport.track_delete_tip(name: vp.name)),
          actions: [
            FButton(
              size: .xs,
              onPress: () async {
                Navigator.of(dialogContext).pop();
                await deleteRecordedTrack(vp.id);
              },
              child: Text(t.action.delete),
            ),
            FButton(
              size: .xs,
              variant: .secondary,
              onPress: () => Navigator.of(dialogContext).pop(),
              child: Text(t.notice.cancel),
            ),
          ],
        );
      },
    );
  }
}

/// 轨迹地图详情
class FeatSportCquptTrackDetailView extends StatefulWidget {
  final String trackId;

  const FeatSportCquptTrackDetailView({super.key, required this.trackId});

  @override
  State<FeatSportCquptTrackDetailView> createState() =>
      _FeatSportCquptTrackDetailViewState();
}

class _FeatSportCquptTrackDetailViewState
    extends State<FeatSportCquptTrackDetailView> {
  BMFMapController? _mapController;
  VirtualPath? _track;

  @override
  void initState() {
    super.initState();
    _loadTrack();
  }

  Future<void> _loadTrack() async {
    if (featRecordedTracks.value.isEmpty) {
      await refreshRecordedTracks();
    }
    final entry = featRecordedTracks.value
        .where((e) => e.track.id == widget.trackId)
        .firstOrNull;
    _track = entry?.track;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final track = _track;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildMap(track)),
            // 顶部信息栏
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                spacing: 4,
                children: [
                  FButton.icon(
                    variant: .outline,
                    size: .sm,
                    onPress: () => context.pop(),
                    child: const Icon(LucideIcons.arrowLeft),
                  ),
                  Expanded(
                    child: FCard(
                      child: Padding(
                        padding: const .symmetric(horizontal: 12, vertical: 6),
                        child: Column(
                          crossAxisAlignment: .start,
                          spacing: 2,
                          children: [
                            Text(
                              track?.name ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: .bold,
                                color: colors.foreground,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                            if (track != null)
                              Text(
                                '${track.points.length} ${t.submodule.cqupt_sport.track_points_unit} · ${track.coordinateType.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                      ),
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

  Widget _buildMap(VirtualPath? track) {
    if (track == null || track.points.isEmpty) {
      return const SizedBox.expand();
    }

    double lat = 0, lng = 0;
    for (final p in track.points) {
      lat += p.lat;
      lng += p.lng;
    }

    return SizedBox.expand(
      child: BMFMapWidget(
        mapOptions: BMFMapOptions(
          center: BMFCoordinate(
            lat / track.points.length,
            lng / track.points.length,
          ),
          zoomLevel: 17,
          buildingsEnabled: true,
          showZoomControl: false,
        ),
        onBMFMapCreated: (controller) {
          _mapController = controller;
          controller.setMapDidLoadCallback(callback: () => _drawTrack(track));
        },
      ),
    );
  }

  // 绘制轨迹线与首尾标记
  Future<void> _drawTrack(VirtualPath track) async {
    final controller = _mapController;
    if (controller == null) return;

    final coords = track.points
        .map((p) => BMFCoordinate(p.lat, p.lng))
        .toList();

    await controller.addPolyline(
      BMFPolyline(
        coordinates: coords,
        width: 8,
        dottedLine: false,
        colors: [Colors.red],
        lineCapType: BMFLineCapType.LineCapButt,
        lineJoinType: BMFLineJoinType.LineJoinRound,
      ),
    );
    await controller.addMarker(
      BMFMarker.icon(
        position: coords.first,
        icon: "assets/icon/icon_start.png",
        identifier: "track_start",
        scaleX: 1.5,
        scaleY: 1.5,
        anchorX: 0.5,
        anchorY: 1,
      ),
    );
    await controller.addMarker(
      BMFMarker.icon(
        position: coords.last,
        icon: "assets/icon/icon_end.png",
        identifier: "track_end",
        scaleX: 1.5,
        scaleY: 1.5,
        anchorX: 0.5,
        anchorY: 1,
      ),
    );

    // 根据轨迹跨度自适应视野
    final lats = track.points.map((p) => p.lat);
    final lngs = track.points.map((p) => p.lng);
    final latSpan =
        lats.reduce((a, b) => a > b ? a : b) -
        lats.reduce((a, b) => a < b ? a : b);
    final lngSpan =
        lngs.reduce((a, b) => a > b ? a : b) -
        lngs.reduce((a, b) => a < b ? a : b);
    final span = latSpan > lngSpan ? latSpan : lngSpan;
    final zoom = span < 0.003
        ? 18.0
        : span < 0.01
        ? 16.0
        : span < 0.05
        ? 14.0
        : 12.0;

    await controller.setCenterCoordinate(coords.first, true);
    await controller.setZoomTo(zoom);
  }
}
