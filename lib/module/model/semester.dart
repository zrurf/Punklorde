import 'package:dart_date/dart_date.dart';

/// 学期索引信息
class SemesterIndex {
  /// 当前学期编号，格式：4位年份 + 1或2（1表示第一学期，2表示第二学期）
  final String current;

  /// 当前学期名称，例如 "2025-2026学年春季第二学期"
  final String name;

  SemesterIndex({required this.current, required this.name});

  factory SemesterIndex.fromJson(Map<String, dynamic> json) {
    return SemesterIndex(
      current: json['current'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'current': current, 'name': name};
}

/// 学期详情
class Semester {
  /// 学期编号，格式同 current
  final String id;

  /// 学期名称
  final String name;

  /// 学期开始日期
  final DateTime start;

  /// 学期结束日期
  final DateTime end;

  /// 学期总周数（1-53）
  final int week;

  /// 学期内的事件列表
  final List<SemesterEvent> events;

  Semester({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.week,
    required this.events,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String,
      name: json['name'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String).addDays(1),
      week: json['week'] as int,
      events: (json['events'] as List)
          .map((e) => SemesterEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': _dateToString(start),
    'end': _dateToString(end),
    'week': week,
    'events': events.map((e) => e.toJson()).toList(),
  };

  /// 计算周数
  int getWeekIndex(DateTime date) {
    if (date.isBefore(start) || date.isAfter(end)) return 0;
    final difference = date.difference(start).inDays;
    if (difference < 0) return 1; // 处理第一周在周一之前开始的情况
    return (difference ~/ 7) + 1;
  }
}

/// 学期内的一个事件
class SemesterEvent {
  /// 事件唯一标识
  final String id;

  /// 事件开始日期
  final DateTime start;

  /// 事件结束日期（可选）
  final DateTime? end;

  /// 事件名称
  final String name;

  SemesterEvent({
    required this.id,
    required this.start,
    this.end,
    required this.name,
  });

  factory SemesterEvent.fromJson(Map<String, dynamic> json) {
    return SemesterEvent(
      id: json['id'] as String,
      start: DateTime.parse(json['start'] as String),
      end: json['end'] != null ? DateTime.parse(json['end'] as String) : null,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'start': _dateToString(start),
    if (end != null) 'end': _dateToString(end!),
    'name': name,
  };
}

/// 将 DateTime 转换为 YYYY-MM-DD 格式的字符串
String _dateToString(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
