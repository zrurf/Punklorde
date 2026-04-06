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

/// 获取当前或下一个事件
///
/// 根据给定的时间，在日程索引中查找当天正在进行或即将开始的事件。
/// 如果当前时间正在进行某个事件，则返回该事件。
/// 如果没有正在进行的事件，则返回当天下一个即将开始的事件。
/// 如果当天再无事件，返回 null。
///
/// [time] 查询的时间点
/// [index] 日程索引数据
/// [eventMap] 事件ID到事件对象的映射（用于解析详情）
/// [slots] 时间槽配置（用于计算结束时间）
/// [semester] 学期信息（用于计算周次）
ScheduleEvent? getCurrentOrNextEvent({
  required DateTime time,
  required CalendarEventIndex index,
  required Map<String, ScheduleEvent> eventMap,
  required List<TimeSlot> slots,
  required Semester semester,
}) {
  // 1. 确定周次和星期
  final week = semester.getWeekIndex(time);
  if (week == 0) return null; // 不在学期内

  final day = time.weekday; // 1 (Mon) - 7 (Sun)
  final currentMinute = time.hour * 60 + time.minute;

  // 2. 获取当天的索引数据
  // index 结构: Map<Week, Map<Day, Map<StartMinute, List<ID>>>>
  final dayIndex = index[week]?[day];
  if (dayIndex == null || dayIndex.isEmpty) return null;

  // 获取所有开始时间并排序
  final startTimes = dayIndex.keys.toList()..sort();

  ScheduleEvent? nextEvent;

  // 3. 遍历查找
  for (final startTime in startTimes) {
    if (startTime > currentMinute) {
      // 找到第一个开始时间晚于当前时间的事件，这即是“下一个事件”
      // 取该时间段的第一个事件（假设同一时间可能有多个事件，这里取一个）
      final ids = dayIndex[startTime];
      if (ids != null && ids.isNotEmpty) {
        nextEvent = eventMap[ids.first];
        break; // 找到最近的下一个，停止查找
      }
    } else {
      // 开始时间早于或等于当前时间，检查是否正在进行
      final ids = dayIndex[startTime];
      if (ids != null && ids.isNotEmpty) {
        for (final id in ids) {
          final event = eventMap[id];
          if (event == null) continue;

          // 计算结束时间
          final endMinute = _getEndMinute(event, slots, startTime);

          // 如果当前时间在 [startTime, endMinute) 范围内
          if (endMinute != null && currentMinute < endMinute) {
            // 找到正在进行的事件，直接返回（优先级最高）
            return event;
          }
        }
      }
    }
  }

  // 4. 返回结果
  // 如果有正在进行的事件，上面已经返回了。
  // 这里返回下一个即将开始的事件（可能为 null）
  return nextEvent;
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
