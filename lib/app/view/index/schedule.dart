import 'dart:async';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/schedule.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/semester.dart';
import 'package:punklorde/utils/etc/theme.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:signals/signals_flutter.dart';

/// 课表主控件
class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});
  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late PageController _pageController;
  final Signal<int> _displayWeekSignal = signal(1);
  final Signal<DateTime> _currentTimeSignal = signal(DateTime.now());
  Timer? _timer;

  // 动态计算的时间槽高度
  double _slotHeight = 0.0;
  // 左侧时间轴宽度
  static const double _timeAxisWidth = 35.0;

  @override
  void initState() {
    super.initState();
    _initController();
    _currentTimeSignal.value = DateTime.now();

    // 初始化时间槽高度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSlotHeight();
    });

    _timer = Timer(Duration(seconds: 60 - _currentTimeSignal.value.second), () {
      _currentTimeSignal.value = DateTime.now();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        _currentTimeSignal.value = DateTime.now();
      });
    });
  }

  void _calculateSlotHeight() {
    final context = this.context;

    // 获取可用屏幕高度（减去顶部导航栏和底部导航栏）
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    final bottomBarHeight = kBottomNavigationBarHeight;
    final availableHeight =
        screenHeight - appBarHeight - bottomBarHeight - 80; // 减去额外 padding

    // 获取时间槽数量
    final slots = currentSchoolSignal.value?.scheduleServices.slots ?? [];
    final slotCount = slots.length;

    if (slotCount > 0) {
      setState(() {
        _slotHeight = availableHeight / slotCount;
      });
    }
  }

  void _initController() {
    final semester = currentSemesterSignal.value;
    final currentWeek = semester?.getWeekIndex(DateTime.now()) ?? 1;
    _displayWeekSignal.value = currentWeek;
    _pageController = PageController(initialPage: currentWeek - 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final semester = currentSemesterSignal.watch(context);
    final scheduleSrv = currentSchoolSignal.watch(context)?.scheduleServices;

    final displayWeek = _displayWeekSignal.watch(context);
    final now = _currentTimeSignal.watch(context);
    final currentRealWeek = semester?.getWeekIndex(now) ?? 0;
    final lastUpdate = lastScheduleUpdateTimeSignal.watch(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // 顶部导航栏
          Padding(
            padding: const .symmetric(horizontal: 16, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                Text(
                  t.title.week_title(week: displayWeek),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: colors.foreground,
                  ),
                ),
                Visibility(
                  visible: currentRealWeek == displayWeek,
                  child: FBadge(
                    child: Text(
                      t.label.current_week,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const Spacer(),
                Visibility(
                  visible:
                      currentRealWeek != displayWeek && currentRealWeek > 0,
                  child: FButton.icon(
                    size: .xs,
                    variant: .secondary,
                    child: const Icon(LucideIcons.arrowLeftToLine),
                    onPress: () {
                      _goToWeek(currentRealWeek);
                    },
                  ),
                ),
                FButton.icon(
                  size: .xs,
                  variant: .secondary,
                  onPress: () {},
                  child: const Icon(LucideIcons.calendarPlus),
                ),
                FButton.icon(
                  size: .xs,
                  variant: .secondary,
                  child: const Icon(LucideIcons.calendarSync),
                  onPress: () {
                    showFDialog(
                      context: context,
                      builder: (context, style, animation) => FDialog(
                        style: style,
                        animation: animation,
                        title: Text(t.action.refresh_schedule),
                        body: Column(
                          spacing: 8,
                          mainAxisSize: .min,
                          children: [
                            Text(
                              t.title.last_update,
                              style: TextStyle(fontSize: 16, fontWeight: .bold),
                            ),
                            Text(
                              (lastUpdate != null)
                                  ? formatDate(lastUpdate)
                                  : t.notice.never_updated,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        actions: [
                          FButton(
                            size: .xs,
                            variant: .primary,
                            onPress: () async {
                              context.loaderOverlay.show();
                              await pullSchedule();
                              if (context.mounted) {
                                context.loaderOverlay.hide();
                                Navigator.of(context).pop();
                              }
                            },
                            prefix: const Icon(LucideIcons.rotateCw),
                            child: Text(t.action.refresh_schedule),
                          ),
                          FButton(
                            size: .xs,
                            variant: .secondary,
                            onPress: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(t.notice.cancel),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // 课表主体区域
          Expanded(child: _buildPageView(semester, scheduleSrv)),
        ],
      ),
    );
  }

  Widget _buildPageView(Semester? semester, ScheduleService? scheduleSrv) {
    if (semester == null || scheduleSrv == null) {
      return Center(
        child: Text(
          t.notice.failed_get_data,
          style: TextStyle(fontSize: 20, color: context.theme.colors.error),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: semester.week,
      onPageChanged: (index) {
        _displayWeekSignal.value = index + 1;
      },
      itemBuilder: (context, index) {
        final weekNumber = index + 1;
        return _WeekTable(
          key: ValueKey('week_$weekNumber'),
          weekNumber: weekNumber,
          semester: semester,
          slots: scheduleSrv.slots,
          currentTime: _currentTimeSignal.value,
          slotHeight: _slotHeight,
          timeAxisWidth: _timeAxisWidth,
        );
      },
    );
  }

  void _goToWeek(int week) {
    if (week < 1) return;
    _pageController.animateToPage(
      week - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

/// 单周课表视图组件
/// 使用 Stack 布局实现跨时间槽课程显示
class _WeekTable extends StatelessWidget {
  final int weekNumber;
  final Semester semester;
  final List<TimeSlot> slots;
  final DateTime currentTime;
  final double slotHeight;
  final double timeAxisWidth;

  const _WeekTable({
    super.key,
    required this.weekNumber,
    required this.semester,
    required this.slots,
    required this.currentTime,
    required this.slotHeight,
    required this.timeAxisWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final dateFmt = DateFormat('M/d');
    final weekStartDate = semester.start.add(
      Duration(days: (weekNumber - 1) * 7),
    );

    // 监听信号
    final eventIndex = calendarEventIndexSignal.watch(context);
    final baseEvents = scheduleBaseEventsSignal.watch(context);
    final customEvents = scheduleCustomEventsSignal.watch(context);

    final isCurrentWeek = semester.getWeekIndex(currentTime) == weekNumber;
    final todayWeekday = currentTime.weekday;

    // 计算总高度
    final totalHeight = slots.length * slotHeight;

    return Column(
      children: [
        // 顶部星期栏
        _buildHeader(
          dateFmt,
          weekStartDate,
          colors,
          isCurrentWeek,
          todayWeekday,
        ),
        // 课表网格与内容
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // 1. 底层：网格背景与左侧时间轴
                  _buildGridBackground(colors, isCurrentWeek, todayWeekday),

                  // 2. 中层：课程卡片 (支持跨槽)
                  _buildEventLayer(
                    context,
                    eventIndex,
                    baseEvents,
                    customEvents,
                    colors,
                  ),

                  // 3. 顶层：当前时间线
                  if (isCurrentWeek) _buildTimeLine(context, todayWeekday),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建顶部日期头部
  Widget _buildHeader(
    DateFormat dateFmt,
    DateTime weekStartDate,
    FColors colors,
    bool isCurrentWeek,
    int todayWeekday,
  ) {
    final labels = [
      t.label.calender_mon,
      t.label.calender_tue,
      t.label.calender_wed,
      t.label.calender_thu,
      t.label.calender_fri,
      t.label.calender_sat,
      t.label.calender_sun,
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: timeAxisWidth),
          for (int i = 0; i < 7; i++)
            Expanded(
              child: Container(
                decoration: isCurrentWeek && (i + 1) == todayWeekday
                    ? BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        border: Border(
                          bottom: BorderSide(color: colors.primary, width: 2),
                        ),
                        borderRadius: const .vertical(top: .circular(8)),
                      )
                    : null,
                child: Center(
                  child: Column(
                    spacing: 4,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: .w600,
                          color: colors.foreground,
                        ),
                      ),
                      Text(
                        dateFmt.format(weekStartDate.add(Duration(days: i))),
                        style: TextStyle(
                          fontSize: 10,
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
    );
  }

  /// 构建背景
  Widget _buildGridBackground(
    FColors colors,
    bool isCurrentWeek,
    int todayWeekday,
  ) {
    return Row(
      children: [
        // 左侧时间轴
        SizedBox(
          width: timeAxisWidth,
          child: Column(
            children: [
              for (final slot in slots)
                Container(
                  height: slotHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.border, width: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      spacing: 2,
                      mainAxisAlignment: .center,
                      crossAxisAlignment: .center,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          slot.index.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.foreground,
                            fontFamily: 'AlteDIN1451',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          formatDayMinutes(slot.startMinutes),
                          style: TextStyle(
                            fontSize: 8,
                            color: colors.mutedForeground,
                          ),
                        ),
                        Text(
                          formatDayMinutes(slot.endMinutes),
                          style: TextStyle(
                            fontSize: 8,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 右侧课程网格区域
        Expanded(
          child: Row(
            children: [
              for (int day = 1; day <= 7; day++)
                Expanded(
                  child: Column(
                    children: [
                      for (int i = 0; i < slots.length; i++)
                        Container(
                          height: slotHeight,
                          decoration: BoxDecoration(
                            color: isCurrentWeek && day == todayWeekday
                                ? colors.primary.withValues(alpha: 0.05)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建课程层
  Widget _buildEventLayer(
    BuildContext context,
    CalendarEventIndex eventIndex,
    BuiltMap<String, ScheduleEvent> baseEvents,
    BuiltMap<String, ScheduleEvent> customEvents,
    FColors colors,
  ) {
    final List<Widget> eventCards = [];

    // 屏幕宽度用于计算列宽
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = (screenWidth - timeAxisWidth) / 7;

    // 遍历该周每一天
    for (int day = 1; day <= 7; day++) {
      // 获取该天所有开始时间的映射
      final dayMap = eventIndex[weekNumber]?[day];
      if (dayMap == null) continue;

      // 遍历该天的所有开始时间点
      dayMap.forEach((startMinutes, ids) {
        for (final id in ids) {
          final event = customEvents[id] ?? baseEvents[id];
          if (event == null) continue;

          // 1. 计算垂直位置
          // 找到开始时间对应的时间槽索引
          final startSlotIndex = slots.indexWhere(
            (s) => s.startMinutes == startMinutes,
          );
          if (startSlotIndex == -1) continue;

          // 计算跨越的槽数量 (默认为1)
          int spanCount = event.timeSlotCount ?? 1;
          // 确保不越界
          if (startSlotIndex + spanCount > slots.length) {
            spanCount = slots.length - startSlotIndex;
          }

          final double top = startSlotIndex * slotHeight;
          final double height = spanCount * slotHeight;

          // 2. 计算水平位置
          final double left = timeAxisWidth + (day - 1) * columnWidth;

          // 处理同一时间段有多个课程的情况（重叠显示）
          // 这里简化处理：如果同一时间点有多个ID，平分宽度
          final int sameSlotCount = ids.length;
          final int indexInSlot = ids.indexOf(id);
          final double unitWidth = columnWidth / sameSlotCount;

          // 宽度略微减小以留出间隙
          final double cardWidth = unitWidth * 0.95;
          final double cardLeft = left + (indexInSlot * unitWidth);

          // 3. 创建卡片
          eventCards.add(
            Positioned(
              top: top,
              left: cardLeft,
              height: height,
              width: cardWidth,
              child: _buildEventCard(context, event, spanCount > 1),
            ),
          );
        }
      });
    }

    return Stack(
      clipBehavior: Clip.none, // 允许略微溢出（如果有边距）
      children: eventCards,
    );
  }

  /// 构建单个课程卡片 UI
  Widget _buildEventCard(
    BuildContext context,
    ScheduleEvent event,
    bool isMultiSlot,
  ) {
    final colors = context.theme.colors;
    final eventColor = event.color != null
        ? Color(event.color!)
        : colors.primary;

    return GestureDetector(
      onTap: () => currentSchoolSignal.value?.scheduleServices.openEventDetail(
        context,
        event,
      ),
      child: Container(
        margin: const .symmetric(horizontal: 0.5, vertical: 1.5), // 卡片间隙
        decoration: BoxDecoration(
          color: eventColor.withValues(
            alpha: (isDarkMode(context)) ? 0.8 : 0.15,
          ),
          borderRadius: .circular(6),
        ),
        padding: const .symmetric(vertical: 6, horizontal: 4),
        alignment: .topLeft,
        child: Column(
          crossAxisAlignment: .center,
          children: [
            Text(
              event.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: (isDarkMode(context))
                    ? colors.primaryForeground.withValues(alpha: 0.9)
                    : eventColor,
              ),
              maxLines: isMultiSlot ? 3 : 2, // 根据是否跨槽调整最大行数
              overflow: .ellipsis,
              textAlign: .center,
            ),
            const Spacer(),
            if (event.location != null)
              Text(
                event.location!,
                style: TextStyle(
                  fontSize: 10,
                  color: (isDarkMode(context))
                      ? colors.primaryForeground.withValues(alpha: 0.9)
                      : eventColor,
                ),
                maxLines: 2,
                overflow: .fade,
                textAlign: .center,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建时间线
  Widget _buildTimeLine(BuildContext context, int todayWeekday) {
    final colors = context.theme.colors;
    final now = currentTime;
    final currentMinutes = now.hour * 60 + now.minute;

    TimeSlot? lastSlot;
    double top = -1;

    // 查找并计算时间线位置
    for (final (i, slot) in slots.indexed) {
      if (currentMinutes >= slot.startMinutes &&
          currentMinutes < slot.endMinutes) {
        final progressInSlot =
            (currentMinutes - slot.startMinutes) /
            (slot.endMinutes - slot.startMinutes);
        top = (i + progressInSlot) * slotHeight;
        break;
      }
      if (currentMinutes >= (lastSlot?.endMinutes ?? 0) &&
          currentMinutes < slot.startMinutes) {
        top = i * slotHeight;
        break;
      }
      if (i == slots.length - 1 && currentMinutes >= slot.endMinutes) {
        top = (i + 1) * slotHeight;
        break;
      }
      lastSlot = slot;
    }

    if (top < 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = (screenWidth - timeAxisWidth) / 7;

    final double left = timeAxisWidth + (todayWeekday - 1) * columnWidth;

    return Positioned(
      top: top,
      left: left,
      right: 0,
      child: Row(
        children: [
          Container(
            padding: const .symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: .circular(4),
            ),
            child: Text(
              DateFormat('H:mm').format(now),
              style: TextStyle(fontSize: 10, color: colors.primaryForeground),
            ),
          ),
          Expanded(child: Container(height: 1.5, color: colors.primary)),
        ],
      ),
    );
  }
}
