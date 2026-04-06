// 当前学期
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:punklorde/common/constant/endpoint.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/resource.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/semester.dart';
import 'package:punklorde/utils/schedule.dart';
import 'package:signals/signals_flutter.dart';

/// 当前学期信息
final Signal<Semester?> currentSemesterSignal = signal(null);

/// 日程表基础事件
final Signal<BuiltMap<String, ScheduleEvent>> scheduleBaseEventsSignal = signal(
  BuiltMap<String, ScheduleEvent>(),
);

/// 日程表自定义事件
final Signal<BuiltMap<String, ScheduleEvent>> scheduleCustomEventsSignal =
    signal(BuiltMap<String, ScheduleEvent>());

// 初始化应用状态
void initScheduleStatus() {
  effect(() {
    storeScheduleStatus();
  });
}

/// 合成索引 Signal
/// 使用 computed 实现自动化依赖追踪和结构化共享（增量更新）
final calendarEventIndexSignal = computed<CalendarEventIndex>(() {
  final semester = currentSemesterSignal.value;
  final scheduleService = currentSchoolSignal.value?.scheduleServices;
  final baseEvents = scheduleBaseEventsSignal.value;
  final customEvents = scheduleCustomEventsSignal.value;

  if (semester == null || scheduleService == null) {
    return BuiltMap<int, BuiltMap<int, BuiltMap<int, BuiltList<String>>>>();
  }

  // 1. 收集需要被取消的事件 ID
  final cancelIds = customEvents.values
      .where((e) => e.type == ScheduleEventType.cancel)
      .map((e) => e.id)
      .toSet();

  // 2. 合并基础事件、补充事件和自定义事件，过滤掉被取消的
  final validEvents = [
    ...baseEvents.values.where((e) => !cancelIds.contains(e.id)),
    ...customEvents.values.where((e) => e.type != ScheduleEventType.cancel),
  ];

  // 3. 构建三维 Map (使用可变 Builder 以获得最佳构建性能)
  final weekMapBuilder =
      MapBuilder<int, MapBuilder<int, MapBuilder<int, ListBuilder<String>>>>();

  for (final event in validEvents) {
    final timeInfo = normalizeEventTime(scheduleService.slots, event);
    if (timeInfo == null) continue;

    final weeks = getActiveWeeks(event, semester);

    for (final week in weeks) {
      // 获取或创建该周的 MapBuilder
      final dayMapBuilder = weekMapBuilder.putIfAbsent(
        week,
        () => MapBuilder<int, MapBuilder<int, ListBuilder<String>>>(),
      );

      // 获取或创建该天的 MapBuilder
      final timeMapBuilder = dayMapBuilder.putIfAbsent(
        timeInfo.$1,
        () => MapBuilder<int, ListBuilder<String>>(),
      );

      // 获取或创建该时间段的 ListBuilder
      final idListBuilder = timeMapBuilder.putIfAbsent(
        timeInfo.$2,
        () => ListBuilder<String>(),
      );

      // 追加事件 ID (同一时间段允许多个事件)
      idListBuilder.add(event.id);
    }
  }

  // 4. 将可变 Builder 深度转换为不可变的 BuiltMap
  final builtWeekMap = weekMapBuilder.build();
  final resultBuilder =
      MapBuilder<int, BuiltMap<int, BuiltMap<int, BuiltList<String>>>>();

  for (final weekEntry in builtWeekMap.entries) {
    final builtDayMap = weekEntry.value.build();
    final dayResultBuilder =
        MapBuilder<int, BuiltMap<int, BuiltList<String>>>();

    for (final dayEntry in builtDayMap.entries) {
      final builtTimeMap = dayEntry.value.build();
      final timeResultBuilder = MapBuilder<int, BuiltList<String>>();

      for (final timeEntry in builtTimeMap.entries) {
        timeResultBuilder[timeEntry.key] = timeEntry.value.build();
      }
      dayResultBuilder[dayEntry.key] = timeResultBuilder.build();
    }
    resultBuilder[weekEntry.key] = dayResultBuilder.build();
  }

  return resultBuilder.build();
});

final Signal<DateTime?> lastScheduleUpdateTimeSignal = signal(null);

bool pullScheduleLock = false;

/// 从学校配置拉取课表
Future<bool> pullSchedule() async {
  try {
    if (pullScheduleLock) throw Exception('Pull schedule locked');
    pullScheduleLock = true;
    final scheduleService = currentSchoolSignal.value?.scheduleServices;
    if (scheduleService == null) throw Exception('No schedule service');
    final semester = currentSemesterSignal.value;
    if (semester == null) throw Exception('No semester');
    final user = scheduleService.getCredential();
    if (user == null) throw Exception('No user');
    final events = await scheduleService.getBaseEvents(semester, user);
    if (events == null) throw Exception('No events');
    scheduleBaseEventsSignal.value = BuiltMap<String, ScheduleEvent>({
      for (var e in events) e.id: e,
    });
    lastScheduleUpdateTimeSignal.value = DateTime.now();
    return true;
  } catch (e) {
    return false;
  } finally {
    pullScheduleLock = false;
  }
}

// 存储层
void storeScheduleStatus() {
  final storage = StorageService();
  if (scheduleBaseEventsSignal.value.isNotEmpty) {
    storage.putList(
      'base',
      scheduleBaseEventsSignal.value.values.map((v) => v.toJson()).toList(),
      instance: scheduleMMKV,
    );
  }
  if (scheduleCustomEventsSignal.value.isNotEmpty) {
    storage.putList(
      'custom',
      scheduleCustomEventsSignal.value.values.map((v) => v.toJson()).toList(),
      instance: scheduleMMKV,
    );
  }
  if (lastScheduleUpdateTimeSignal.value != null) {
    storage.putInt(
      'update',
      lastScheduleUpdateTimeSignal.value?.millisecondsSinceEpoch ?? 0,
      instance: scheduleMMKV,
    );
  }
}

Future<void> loadScheduleStatus() async {
  final storage = StorageService();

  final baseEvents = await storage.getList('base', instance: scheduleMMKV);
  final customEvents = await storage.getList('custom', instance: scheduleMMKV);
  final updateTime = storage.getInt('update', instance: scheduleMMKV);

  if (baseEvents != null) {
    final Map<String, ScheduleEvent> baseMap = {};

    for (final v in baseEvents) {
      if (v == null) continue;
      final v1 = ScheduleEvent.fromJson(Map<String, dynamic>.from(v));
      baseMap[v1.id] = v1;
    }

    scheduleBaseEventsSignal.value = BuiltMap<String, ScheduleEvent>(baseMap);
  }

  if (customEvents != null) {
    final Map<String, ScheduleEvent> customMap = {};

    for (final v in customEvents) {
      if (v == null) continue;
      final v1 = ScheduleEvent.fromJson(Map<String, dynamic>.from(v));
      customMap[v1.id] = v1;
    }

    scheduleCustomEventsSignal.value = BuiltMap<String, ScheduleEvent>(
      customMap,
    );
  }

  lastScheduleUpdateTimeSignal.value = updateTime != 0
      ? DateTime.fromMillisecondsSinceEpoch(updateTime)
      : null;
}

Future<bool> loadSemester() async {
  // 加载学期信息
  if (currentSchoolSignal.value != null) {
    try {
      final calendarIdxPath = await resourceManager.loadResource(
        epCalendarIndex,
        expiry: const Duration(days: 7),
      );

      if (calendarIdxPath == null) {
        return false;
      }

      final calendarIdxStr = await File(calendarIdxPath).readAsString();

      final calendarIdx = SemesterIndex.fromJson(jsonDecode(calendarIdxStr));

      if (calendarIdx.current.isEmpty) {
        return false;
      }

      final semesterPath = await resourceManager.loadResource(
        epCalendarSemester(currentSchoolSignal.value!.id, calendarIdx.current),
        expiry: const Duration(days: 1),
      );

      if (semesterPath == null) {
        return false;
      }

      final semesterStr = await File(semesterPath).readAsString();

      currentSemesterSignal.value = Semester.fromJson(jsonDecode(semesterStr));

      return true;
    } catch (e) {
      return false;
    }
  } else {
    return false;
  }
}
