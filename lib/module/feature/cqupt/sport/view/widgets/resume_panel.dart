import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/client.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/model/sport.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/resource/resource.dart';
import 'package:punklorde/module/feature/cqupt/sport/utils/time.dart';
import 'package:signals/signals_flutter.dart';

/// 续跑面板：选择进行中的运动记录与虚拟路线后开始续跑
///
/// mobile/list 返回的里程/耗时不可靠，选中记录后通过 /sportRecord/info 获取真实数据
class ResumePanel extends StatefulWidget {
  final List<WxSportRecord> records;
  final void Function(
    WxSportRecord record,
    VirtualPath route,
    SportInfoResult info,
  )
  onConfirm;

  const ResumePanel({
    super.key,
    required this.records,
    required this.onConfirm,
  });

  @override
  State<ResumePanel> createState() => _ResumePanelState();
}

class _ResumePanelState extends State<ResumePanel> {
  final ApiClient _apiClient = ApiClient();

  WxSportRecord? _record;
  VirtualPath? _route;
  bool _loadingRoutes = false;

  // 记录编号 -> 真实运动信息
  final Map<String, SportInfoResult> _infoCache = {};
  final Set<String> _loadingInfo = Set();
  final Set<String> _failedInfo = Set();

  @override
  void initState() {
    super.initState();
    _ensureRoutesLoaded();
  }

  // 未选择运动预设时，自动加载第一个预设以提供可选路线
  Future<void> _ensureRoutesLoaded() async {
    if (featVirtualPaths.value != null && featVirtualPaths.value!.isNotEmpty) {
      return;
    }
    setState(() => _loadingRoutes = true);
    if (featMotionProfileIndex.value == null ||
        featVirtualPathIndex.value == null) {
      await loadReourceIndex();
    }
    final index = featMotionProfileIndex.value;
    if (index != null && index.isNotEmpty) {
      await loadMotionProfile(index.keys.first);
    }
    if (mounted) setState(() => _loadingRoutes = false);
  }

  Future<void> _switchProfile(ResourceIndexEntry entry) async {
    setState(() => _loadingRoutes = true);
    _route = null;
    await loadMotionProfile(entry.id);
    if (mounted) setState(() => _loadingRoutes = false);
  }

  void _selectRecord(WxSportRecord record) {
    setState(() => _record = record);
    _loadInfo(record);
  }

  // 拉取记录的真实里程/耗时/轨迹点
  Future<void> _loadInfo(WxSportRecord record) async {
    final no = record.sportRecordNo;
    if (_infoCache.containsKey(no) || _loadingInfo.contains(no)) return;

    _loadingInfo.add(no);
    final info = await _apiClient.getSportInfo(no);
    _loadingInfo.remove(no);
    if (!mounted) return;
    setState(() {
      if (info != null) {
        _infoCache[no] = info;
        _failedInfo.remove(no);
      } else {
        _failedInfo.add(no);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: .infinity,
        width: .infinity,
        decoration: BoxDecoration(
          color: colors.background,
          border: .symmetric(horizontal: BorderSide(color: colors.border)),
        ),
        child: SingleChildScrollView(
          padding: const .symmetric(horizontal: 16, vertical: 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                spacing: 8,
                children: [
                  Text(
                    t.submodule.cqupt_sport.resume_title,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                  ),
                  Text(
                    t.submodule.cqupt_sport.resume_hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const FDivider(),
                  // 进行中的运动记录
                  Text(
                    t.submodule.cqupt_sport.resume_unfinished_run,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                  ),
                  for (final record in widget.records) _buildRecordTile(record),
                  const SizedBox(height: 8),
                  // 虚拟路线
                  Text(
                    t.submodule.cqupt_sport.resume_route,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                  ),
                  SignalBuilder(
                    builder: (context) {
                      final profiles = featMotionProfileIndex.value;
                      final pathList =
                          featVirtualPaths.value?.values.toList() ??
                          <VirtualPath>[];
                      final currentProfile =
                          (featMotionProfile.value == null || profiles == null)
                          ? null
                          : profiles[featMotionProfile.value!.id];

                      return Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          // 运动预设切换（路线来源）
                          if (profiles != null && profiles.isNotEmpty)
                            FSelect<ResourceIndexEntry>.rich(
                              size: .sm,
                              label: Text(
                                t.submodule.cqupt_sport.motion_profile,
                              ),
                              control: .managed(
                                initial: currentProfile,
                                onChange: (v) {
                                  if (v != null) _switchProfile(v);
                                },
                              ),
                              format: (v) => v.name,
                              children: [
                                for (final v in profiles.values)
                                  .item(title: Text(v.name), value: v),
                              ],
                            ),
                          if (_loadingRoutes)
                            Padding(
                              padding: const .symmetric(vertical: 12),
                              child: Row(
                                spacing: 8,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: FCircularProgress(size: .xs),
                                  ),
                                  Text(
                                    t.notice.loading,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            for (final vp in pathList) _buildRouteTile(vp),
                            if (pathList.isEmpty)
                              Padding(
                                padding: const .symmetric(vertical: 8),
                                child: Text(
                                  t.submodule.cqupt_sport.resume_no_routes,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // 确认前必须拿到真实运动数据
                  finalInfoReady()
                      ? FButton(
                          onPress: (_record != null && _route != null)
                              ? () => widget.onConfirm(
                                  _record!,
                                  _route!,
                                  _infoCache[_record!.sportRecordNo]!,
                                )
                              : null,
                          child: Row(
                            mainAxisAlignment: .center,
                            spacing: 6,
                            children: [
                              const Icon(
                                LucideIcons.flagTriangleRight,
                                size: 18,
                              ),
                              Text(t.submodule.cqupt_sport.resume_start),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const .symmetric(vertical: 4),
                          child: Text(
                            t.submodule.cqupt_sport.resume_loading_info,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 当前选中的记录是否已获取到真实运动数据
  bool finalInfoReady() {
    final no = _record?.sportRecordNo;
    if (no == null) return false;
    return _infoCache.containsKey(no);
  }

  Widget _buildRecordTile(WxSportRecord record) {
    final colors = context.theme.colors;
    final selected = _record?.sportRecordNo == record.sportRecordNo;
    final no = record.sportRecordNo;
    final tail = (no.length > 6) ? no.substring(no.length - 6) : no;

    return Padding(
      padding: const .symmetric(vertical: 2),
      child: FCard(
        style: .delta(
          decoration: .boxDelta(
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: .circular(8),
          ),
        ),
        child: InkWell(
          onTap: () => _selectRecord(record),
          child: Padding(
            padding: const .all(4),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  color: selected ? colors.primary : colors.mutedForeground,
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 2,
                    children: [
                      Text(
                        record.placeName ?? t.submodule.cqupt_sport.record,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: .bold,
                          color: colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                      Text(
                        _buildSubtitle(record, tail),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 副标题：未选中显示编号；选中后展示从 info 接口获取的真实里程与耗时
  String _buildSubtitle(WxSportRecord record, String tail) {
    final no = record.sportRecordNo;
    if (_record?.sportRecordNo != no) {
      return '#...$tail';
    }
    if (_loadingInfo.contains(no)) {
      return '${t.notice.loading} · #...$tail';
    }
    final info = _infoCache[no];
    if (info == null) {
      return '${t.submodule.cqupt_sport.resume_info_failed} · #...$tail';
    }
    return '${t.submodule.cqupt_sport.distance} ${(info.mileage * 1000).round()}m'
        ' · ${formatDuration(Duration(seconds: info.timeConsuming.round()))}'
        ' · ${info.points.length} ${t.submodule.cqupt_sport.track_points_unit}';
  }

  Widget _buildRouteTile(VirtualPath route) {
    final colors = context.theme.colors;
    final selected = _route?.id == route.id;

    return Padding(
      padding: const .symmetric(vertical: 2),
      child: FCard(
        style: .delta(
          decoration: .boxDelta(
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: .circular(8),
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _route = route),
          child: Padding(
            padding: const .all(4),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  LucideIcons.route,
                  color: selected ? colors.primary : colors.mutedForeground,
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 2,
                    children: [
                      Text(
                        route.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: .bold,
                          color: colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                      Text(
                        '${route.points.length} ${t.submodule.cqupt_sport.track_points_unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.check, color: colors.primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
