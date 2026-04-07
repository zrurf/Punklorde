import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/semester.dart';

/// 将事件的时间锚点统一归一化为 (星期, 开始分钟数)
(int day, int startMinutes)? normalizeEventTime(
  List<TimeSlot> slots,
  ScheduleEvent event,
) {
  switch (event.anchor) {
    case ScheduleAnchor.slot:
      if (event.activeDay == null || event.timeSlotIndex == null) return null;
      final slot = slots
          .where((s) => s.index == event.timeSlotIndex)
          .firstOrNull;
      if (slot == null) return null;
      return (event.activeDay!, slot.startMinutes);

    case ScheduleAnchor.relative:
      if (event.relativeStartMinutes == null) return null;
      final totalMinutes = event.relativeStartMinutes!;
      // relativeStartMinutes 是距周一0点的分钟数，1440为一天
      final day = ((totalMinutes ~/ 1440) % 7) + 1;
      final time = totalMinutes % 1440;
      return (day.clamp(1, 7), time);

    case ScheduleAnchor.absolute:
    case ScheduleAnchor.point:
      if (event.absoluteStart == null) return null;
      final date = event.absoluteStart!.toLocal();
      // DateTime.weekday: 1 = 周一, 7 = 周日
      return (date.weekday, date.hour * 60 + date.minute);
  }
}

/// 获取事件激活的周次列表
List<int> getActiveWeeks(ScheduleEvent event, Semester semester) {
  // 1. 如果指定了具体周次，直接使用
  if (event.activeWeeks != null && event.activeWeeks!.isNotEmpty) {
    return event.activeWeeks!;
  }
  // 2. 绝对时间/时间点事件，根据学期开始时间计算所在周
  if (event.absoluteStart != null) {
    final w = semester.getWeekIndex(event.absoluteStart!);
    return w > 0 ? [w] : [];
  }
  // 3. 兜底：如果没有周次也没有绝对时间，默认全学期生效
  return List.generate(semester.week, (index) => index + 1);
}

/// 获取当前正在进行的事件
ScheduleEvent? getCurrentEvent({
  required DateTime time,
  required CalendarEventIndex index,
  required Map<String, ScheduleEvent> eventMap,
  required List<TimeSlot> slots,
  required Semester semester,
}) {
  final week = semester.getWeekIndex(time);
  if (week == 0) return null;
  final day = time.weekday;
  final currentMinute = time.hour * 60 + time.minute;
  final dayIndex = index[week]?[day];
  if (dayIndex == null || dayIndex.isEmpty) return null;

  final startTimes = dayIndex.keys.toList()..sort();

  for (final startTime in startTimes) {
    if (startTime <= currentMinute) {
      final ids = dayIndex[startTime];
      if (ids != null && ids.isNotEmpty) {
        for (final id in ids) {
          final event = eventMap[id];
          if (event == null) continue;
          final endMinute = _getEndMinute(event, slots, startTime);
          // 如果当前时间在 [startTime, endMinute) 范围内，说明正在进行
          if (endMinute != null && currentMinute < endMinute) {
            return event;
          }
        }
      }
    }
  }
  return null;
}

/// 获取下一个即将开始的事件
ScheduleEvent? getNextEvent({
  required DateTime time,
  required CalendarEventIndex index,
  required Map<String, ScheduleEvent> eventMap,
  required List<TimeSlot> slots,
  required Semester semester,
}) {
  final week = semester.getWeekIndex(time);
  if (week == 0) return null;
  final day = time.weekday;
  final currentMinute = time.hour * 60 + time.minute;
  final dayIndex = index[week]?[day];
  if (dayIndex == null || dayIndex.isEmpty) return null;

  final startTimes = dayIndex.keys.toList()..sort();

  for (final startTime in startTimes) {
    // 找到第一个开始时间晚于当前时间的事件
    if (startTime > currentMinute) {
      final ids = dayIndex[startTime];
      if (ids != null && ids.isNotEmpty) {
        return eventMap[ids.first];
      }
    }
  }
  return null;
}

/// 获取当天所有未完成的事件（包括正在进行和尚未开始的）
/// 返回列表已按开始时间排序
List<ScheduleEvent> getRemainingEvents({
  required DateTime time,
  required CalendarEventIndex index,
  required Map<String, ScheduleEvent> eventMap,
  required List<TimeSlot> slots,
  required Semester semester,
}) {
  final week = semester.getWeekIndex(time);
  if (week == 0) return [];

  final day = time.weekday;
  final currentMinute = time.hour * 60 + time.minute;

  // 获取当天的索引
  final dayIndex = index[week]?[day];
  if (dayIndex == null || dayIndex.isEmpty) return [];

  final remainingEvents = <ScheduleEvent>[];

  // 获取所有开始时间并排序
  final startTimes = dayIndex.keys.toList()..sort();

  for (final startTime in startTimes) {
    final ids = dayIndex[startTime];
    if (ids == null) continue;

    for (final id in ids) {
      final event = eventMap[id];
      if (event == null) continue;

      // 计算该事件的结束时间
      final endMinute = _getEndMinute(event, slots, startTime);

      // 筛选逻辑：
      // 1. 结束时间必须存在
      // 2. 结束时间必须大于当前时间（说明事件还未结束）
      // 注意：如果事件已经开始但未结束，也会被包含在内
      if (endMinute != null && endMinute > currentMinute) {
        remainingEvents.add(event);
      }
    }
  }

  return remainingEvents;
}

/// 检测某事件是否在进行中
/// [event]: 要检测的事件
/// [time]: 当前时间点
/// [semester]: 当前学期信息
/// [slots]: 时间槽配置
bool isEventActive({
  required ScheduleEvent event,
  required DateTime time,
  required Semester semester,
  required List<TimeSlot> slots,
}) {
  // 1. 检查是否在激活的周次内
  final activeWeeks = getActiveWeeks(event, semester);
  final currentWeek = semester.getWeekIndex(time);
  if (!activeWeeks.contains(currentWeek)) {
    return false;
  }

  // 2. 获取归一化后的时间信息 (星期, 开始分钟数)
  final timeInfo = normalizeEventTime(slots, event);
  if (timeInfo == null) return false;

  final eventDay = timeInfo.$1;
  final startMinutes = timeInfo.$2;

  // 3. 检查是否是当天
  // DateTime.weekday: 1 (周一) - 7 (周日)
  if (eventDay != time.weekday) {
    return false;
  }

  // 4. 计算结束时间
  final endMinutes = _getEndMinute(event, slots, startMinutes);
  if (endMinutes == null) {
    // 如果无法确定结束时间，通常认为无法判断正在进行，返回 false
    return false;
  }

  // 5. 判断当前时间是否在区间内 [startMinutes, endMinutes)
  final currentMinutes = time.hour * 60 + time.minute;

  return currentMinutes >= startMinutes && currentMinutes < endMinutes;
}

/// 辅助函数：计算事件的结束时间（距当天0点的分钟数）
int? _getEndMinute(ScheduleEvent event, List<TimeSlot> slots, int startMinute) {
  // 1. 基于时间槽
  if (event.anchor == ScheduleAnchor.slot && event.timeSlotIndex != null) {
    final count = event.timeSlotCount ?? 1;
    // 找到结束时的最后一个时间槽
    // timeSlotIndex 是开始节次 (例如 1)
    // 结束节次 index = timeSlotIndex + count - 1
    final endIndex = event.timeSlotIndex! + count - 1;

    try {
      final endSlot = slots.firstWhere((s) => s.index == endIndex);
      return endSlot.endMinutes;
    } catch (e) {
      return null;
    }
  }

  // 2. 基于相对时间
  if (event.anchor == ScheduleAnchor.relative &&
      event.relativeEndMinutes != null) {
    // relativeEndMinutes 是距周一0点的分钟数
    // startMinute 是当天的开始分钟数
    // 我们需要计算当天的结束分钟数
    // 注意：跨天的情况在这里暂不考虑（通常课程不跨天）
    // 假设 relativeEndMinutes 就在同一天
    // 如果 relativeStartMinutes 与 startTime 吻合，我们可以直接计算
    // 但更简单的方法是：结束时间 = 开始时间 + 持续时长
    // 持续时长 = relativeEnd - relativeStart
    if (event.relativeStartMinutes != null) {
      final duration = event.relativeEndMinutes! - event.relativeStartMinutes!;
      return startMinute + duration;
    }
    // 退回：直接使用 relativeEndMinutes 计算星期偏移
    // 这里暂时简化，假设相对时间通常用于特殊日程，若需严谨需结合星期计算
    // 鉴于学校课表主要是时间槽，此处逻辑仅为兜底
    return null;
  }

  // 3. 基于绝对时间
  if (event.anchor == ScheduleAnchor.absolute && event.absoluteEnd != null) {
    return event.absoluteEnd!.hour * 60 + event.absoluteEnd!.minute;
  }

  return null;
}
