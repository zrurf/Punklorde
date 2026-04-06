import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/semester.dart';

// 日期时间（支持 ISO 8601 格式）
final _dateFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");

/// 事件类型
enum ScheduleEventType {
  base, // 基础
  add, // 补充日程
  cancel, // 取消日程
  custom, // 自定义
}

/// 事件时间锚点
enum ScheduleAnchor {
  slot, // 基于时间槽
  relative, // 基于相对时间段
  absolute, // 基于绝对时间段
  point, // 基于时间点
}

/// 时间槽
class TimeSlot {
  final int index; // 索引（第n节课）
  final String name; // 时间槽名称
  final int startMinutes; // 开始时间（距0点的分钟数）
  final int endMinutes; // 结束时间（距0点的分钟数）

  const TimeSlot({
    required this.index,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
  });
}

/// 日程事件
class ScheduleEvent {
  final String id; // 事件唯一标识
  final ScheduleEventType type; // 事件类型
  final ScheduleAnchor anchor; // 时间锚点

  // 基于时间槽
  final List<int>? activeWeeks; // 周次
  final int? activeDay; // 天数
  final int? timeSlotIndex; // 时间槽索引
  final int? timeSlotCount; // 使用时间槽数量

  // 基于相对时间
  final int? relativeStartMinutes; // 相对时间段开始时间（距周一0点的分钟数）
  final int? relativeEndMinutes; // 相对时间段结束时间（距周一0点的分钟数）

  // 基于绝对时间
  final DateTime? absoluteStart; // 绝对时间开始时间（或时间点）
  final DateTime? absoluteEnd; // 绝对时间结束时间

  // 事件通用属性
  final String title; // 事件标题
  final String? description; // 事件描述
  final String? location; // 事件地点
  final int? color; // 标签颜色
  final Map<String, dynamic>? ext; // 扩展属性

  const ScheduleEvent({
    required this.id,
    required this.type,
    required this.anchor,
    this.activeWeeks,
    this.activeDay,
    this.timeSlotIndex,
    this.timeSlotCount,
    this.relativeStartMinutes,
    this.relativeEndMinutes,
    this.absoluteStart,
    this.absoluteEnd,
    required this.title,
    this.description,
    this.location,
    this.color,
    this.ext,
  });

  /// 将对象转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _scheduleEventTypeToString(type),
      'anchor': _scheduleAnchorToString(anchor),
      'activeDay': activeDay,
      'activeWeeks': activeWeeks,
      'timeSlotIndex': timeSlotIndex,
      'timeSlotCount': timeSlotCount,
      'relativeStartMinutes': relativeStartMinutes,
      'relativeEndMinutes': relativeEndMinutes,
      'absoluteStart': absoluteStart != null
          ? _dateFormat.format(absoluteStart!.toUtc())
          : null,
      'absoluteEnd': absoluteEnd != null
          ? _dateFormat.format(absoluteEnd!.toUtc())
          : null,
      'title': title,
      'description': description,
      'location': location,
      'color': color,
      'ext': ext,
    };
  }

  /// 从 JSON Map 创建对象
  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      id: json['id'] as String,
      type: _stringToScheduleEventType(json['type'] as String),
      anchor: _stringToScheduleAnchor(json['anchor'] as String),
      activeDay: json['activeDay'] as int?,
      activeWeeks: (json['activeWeeks'] as List<dynamic>?)?.cast<int>(),
      timeSlotIndex: json['timeSlotIndex'] as int?,
      timeSlotCount: json['timeSlotCount'] as int?,
      relativeStartMinutes: json['relativeStartMinutes'] as int?,
      relativeEndMinutes: json['relativeEndMinutes'] as int?,
      absoluteStart: json['absoluteStart'] != null
          ? _dateFormat.parseUtc(json['absoluteStart'] as String).toLocal()
          : null,
      absoluteEnd: json['absoluteEnd'] != null
          ? _dateFormat.parseUtc(json['absoluteEnd'] as String).toLocal()
          : null,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      color: json['color'] as int?,
      ext: (json['ext'] == null)
          ? null
          : Map<String, dynamic>.from(json['ext']),
    );
  }

  // 枚举转换辅助方法
  static String _scheduleEventTypeToString(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.base:
        return 'base';
      case ScheduleEventType.add:
        return 'add';
      case ScheduleEventType.cancel:
        return 'cancel';
      case ScheduleEventType.custom:
        return 'custom';
    }
  }

  static ScheduleEventType _stringToScheduleEventType(String type) {
    switch (type) {
      case 'base':
        return ScheduleEventType.base;
      case 'add':
        return ScheduleEventType.add;
      case 'cancel':
        return ScheduleEventType.cancel;
      case 'custom':
        return ScheduleEventType.custom;
      default:
        throw ArgumentError('Unknown ScheduleEventType: $type');
    }
  }

  static String _scheduleAnchorToString(ScheduleAnchor anchor) {
    switch (anchor) {
      case ScheduleAnchor.slot:
        return 'slot';
      case ScheduleAnchor.relative:
        return 'relative';
      case ScheduleAnchor.absolute:
        return 'absolute';
      case ScheduleAnchor.point:
        return 'point';
    }
  }

  static ScheduleAnchor _stringToScheduleAnchor(String anchor) {
    switch (anchor) {
      case 'slot':
        return ScheduleAnchor.slot;
      case 'relative':
        return ScheduleAnchor.relative;
      case 'absolute':
        return ScheduleAnchor.absolute;
      case 'point':
        return ScheduleAnchor.point;
      default:
        throw ArgumentError('Unknown ScheduleAnchor: $anchor');
    }
  }
}

/// 课表服务
abstract class ScheduleService {
  /// 时间槽配置数据
  List<TimeSlot> get slots;

  /// 获取身份凭证
  AuthCredential? getCredential();

  /// 获取基础事件
  Future<List<ScheduleEvent>?> getBaseEvents(
    Semester semester,
    AuthCredential credential,
  );

  /// 打开事件详情页面
  void openEventDetail(BuildContext context, ScheduleEvent event);
}

/// 日历控件读取的索引结构体
/// 外层 Key: week (学期周次 1-20)
/// 中层 Key: day (星期 1-7，对应周一至周日)
/// 内层 Key: startMinutes (一天内的开始分钟数 0-1439)
/// Value: ids (该时间段内的事件ID列表)
typedef CalendarEventIndex =
    BuiltMap<int, BuiltMap<int, BuiltMap<int, BuiltList<String>>>>;
