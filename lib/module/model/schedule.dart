// 学期日历
class TermCalendar {
  final String id; // 学期ID
  final String name; // 学期名称
  final DateTime startTime; // 开始时间()
  final DateTime endTime; // 结束时间
  final int weekCount; // 周数

  TermCalendar({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.weekCount,
  });
}

// 时间槽位
class TimeSolt {
  final int id; // 槽位ID（必须为非0正数）
  final String name; // 槽位名称
  final int startTime; // 开始时间
  final int endTime; // 结束时间

  TimeSolt({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });
}

// 日程项
class ScheduleEntry {
  final String id; // 日程项ID
  final String type; // 日程项类型
  final bool isActive; // 是否生效

  final String title; // 日程项标题
  final String? desc; // 日程项描述

  final List<int> period; // 日程周
  final List<int> solt; // 槽位ID（如果为空，则使用时间槽，则使用时间段）
  final int day; // 日程项星期（仅当使用槽位时生效）
  final DateTime startTime; // 日程项开始时间（仅使用时间段时生效）
  final DateTime? endTime; // 日程项结束时间（如果为null，则为时间点）

  final String? location; // 日程项地点

  final Map<String, dynamic>? ext; // 日程项扩展信息

  ScheduleEntry({
    required this.id,
    required this.type,
    required this.isActive,
    required this.title,
    this.desc,
    required this.period,
    required this.solt,
    this.day = 0,
    required this.startTime,
    this.endTime,
    this.location,
    this.ext,
  });
}

// 日程例外
class ScheduleException {
  final String id; // 例外ID
  final String name; // 例外名称
  final String? desc; // 例外描述
  final String action; // 操作类型
  final int week; // 目标周
  final int day; // 目标星期
  final List<int> solt; // 目标槽位
  final ScheduleEntry? newEntry; // 新的日程项

  ScheduleException({
    required this.id,
    required this.name,
    this.desc,
    required this.action,
    required this.week,
    required this.day,
    required this.solt,
    this.newEntry,
  });
}
