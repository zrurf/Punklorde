import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/client.dart';
import 'package:punklorde/module/feature/cqupt/sport/api/model/sport.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/utils/time.dart';
import 'package:signals/signals_flutter.dart';

class FeatSportCquptRecordView extends StatefulWidget {
  const FeatSportCquptRecordView({super.key});

  @override
  State<FeatSportCquptRecordView> createState() =>
      _FeatSportCquptRecordViewState();
}

class _FeatSportCquptRecordViewState extends State<FeatSportCquptRecordView> {
  final ApiClient _apiClient = ApiClient();
  final Signal<List<RecordResult>> _sportRecordSignal = signal([]);
  final Signal<SportStatistics?> _statistics = signal(null);
  final Signal<int> _currentPage = signal(0);

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();

    _apiClient.getSportRecords().then((value) {
      _sportRecordSignal.value = value;
    });

    _apiClient.getSportStat().then((value) {
      _statistics.value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPage = _sportRecordSignal.watch(context).length ~/ _pageSize;

    final startIndex = _currentPage.watch(context) * _pageSize;
    final endIndex = startIndex + _pageSize;

    final currentPageRecords = (_sportRecordSignal.watch(context).isEmpty)
        ? <RecordResult>[]
        : _sportRecordSignal.watch(context).sublist(startIndex, endIndex);

    return Scaffold(
      body: SafeArea(
        child: Column(
          spacing: 8,
          children: [
            FHeader.nested(
              title: Text(t.submodule.cqupt_sport.record),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            Expanded(
              child: ListView.builder(
                padding: const .symmetric(horizontal: 16, vertical: 8),
                itemCount: currentPageRecords.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const .symmetric(vertical: 4),
                      child: _buildStatsCard(),
                    );
                  }
                  if (index == currentPageRecords.length + 1) {
                    return Padding(
                      padding: const .symmetric(vertical: 4),
                      child: Column(
                        children: [
                          const FDivider(),
                          FPagination(
                            control: .managed(
                              initial: _currentPage.watch(context),
                              pages: max(totalPage, 1),
                              onChange: (v) => _currentPage.value = v,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final record = currentPageRecords[index - 1];
                  return Padding(
                    padding: const .symmetric(vertical: 4),
                    child: _buildRecordCard(record),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final colors = context.theme.colors;
    return FCard.raw(
      child: Padding(
        padding: const .all(16),
        child: (_statistics.watch(context) == null)
            ? Center(
                child: Text(
                  (featPortalCredential.watch(context) == null)
                      ? t.submodule.cqupt_sport.portal_user_not_login
                      : t.submodule.cqupt_sport.failed_to_get_stats,
                  style: TextStyle(fontSize: 15, color: colors.destructive),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 16,
                children: [
                  // 运动总次数
                  _buildStatColumn(
                    context,
                    mainValue: _statistics.watch(context)?.totalCount ?? 0,
                    mainDeno: _statistics.watch(context)?.targetTotalCount ?? 0,
                    mainLabel: t.submodule.cqupt_sport.total_count,
                    subValue: _statistics.watch(context)?.totalAddCount ?? 0,
                    alignment: CrossAxisAlignment.center,
                  ),

                  // 跑步次数
                  _buildStatColumn(
                    context,
                    mainValue: _statistics.watch(context)?.runCount ?? 0,
                    mainDeno: _statistics.watch(context)?.targetRunCount ?? 0,
                    mainLabel: t.submodule.cqupt_sport.run_count,
                    subValue: _statistics.watch(context)?.runAddCount ?? 0,
                    alignment: CrossAxisAlignment.center,
                  ),

                  // 其他次数
                  _buildStatColumn(
                    context,
                    mainValue: _statistics.watch(context)?.otherCount ?? 0,
                    mainDeno: _statistics.watch(context)?.targetOtherCount ?? 0,
                    mainLabel: t.submodule.cqupt_sport.other_count,
                    subValue: _statistics.watch(context)?.otherAddCount ?? 0,
                    alignment: CrossAxisAlignment.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required int mainValue,
    required int mainDeno,
    required int subValue,
    required String mainLabel,
    required CrossAxisAlignment alignment,
  }) {
    final colors = context.theme.colors;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignment,
        spacing: 4,
        children: [
          Text(
            mainLabel,
            style: TextStyle(color: colors.mutedForeground, fontSize: 10),
          ),
          Row(
            mainAxisAlignment: .center,
            crossAxisAlignment: .end,
            spacing: 2,
            children: [
              Text(
                mainValue.toString(),
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 26,
                  fontWeight: .bold,
                  fontFamily: 'AlteDIN1451', // 使用数字专用字体
                  letterSpacing: 1,
                ),
              ),
              (subValue > 0)
                  ? Text(
                      '+$subValue',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 21,
                        fontWeight: .bold,
                        fontFamily: 'AlteDIN1451', // 使用数字专用字体
                        letterSpacing: 1,
                      ),
                    )
                  : null,
              Text(
                "/$mainDeno",
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 16,
                  fontFamily: 'AlteDIN1451',
                  letterSpacing: 1,
                ),
              ),
            ].nonNulls.toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(RecordResult record) {
    final colors = context.theme.colors;
    return FCard.raw(
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 8),
        child: Column(
          spacing: 8,
          children: [
            Row(
              spacing: 4,
              children: [
                Text(
                  record.sportsStartTime,
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
                Spacer(),
                FBadge(
                  variant: (record.isValid) ? .primary : .destructive,
                  child: Text(
                    record.isValid
                        ? t.submodule.cqupt_sport.valid
                        : t.submodule.cqupt_sport.invalid,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            Text(
              record.placeName,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
            ),
            Text(
              (record.sportsType == "1")
                  ? t.submodule.cqupt_sport.sport_type_run
                  : t.submodule.cqupt_sport.sport_type_other,
              style: TextStyle(
                fontSize: 21,
                color: colors.foreground,
                fontWeight: .bold,
              ),
            ),
            Visibility(
              visible: !record.isValid,
              child: Text(
                record.reason ?? '',
                style: TextStyle(fontSize: 13, color: colors.error),
              ),
            ),
            Row(
              spacing: 8,
              children: [
                Text(
                  formatDuration(Duration(seconds: record.duration.round())),
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
                Text(
                  '${record.distance.round()}m',
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
                Spacer(),
                Visibility(
                  visible: record.isValid || !record.isAppeal,
                  child: FBadge(
                    variant: (record.isValid)
                        ? ((record.reckonType == "1") ? .primary : .secondary)
                        : .outline,
                    child: Text(
                      (record.isValid)
                          ? ((record.reckonType == "1")
                                ? t.submodule.cqupt_sport.sport_exam
                                : t.submodule.cqupt_sport.sport_addition)
                          : t.submodule.cqupt_sport.appealable,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
