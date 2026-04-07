// 当前学期
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:punklorde/common/constant/endpoint.dart';
import 'package:punklorde/core/service/widget_service.dart';
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

/// 当前正在进行的事件
final Signal<ScheduleEvent?> currentActiveEventSignal = signal(null);

/// 下一个即将开始的事件
final Signal<ScheduleEvent?> nextUpcomingEventSignal = signal(null);

/// 当天所有未完成的事件列表（按时间正序排列）
final Signal<List<ScheduleEvent>> todayRemainingEventsSignal = signal([]);

bool isFirstTrigger = true;

// 初始化应用状态
void initScheduleStatus() {
  effect(() {
    storeScheduleStatus();
  });

  effect(() {
    if (isFirstTrigger) {
      isFirstTrigger = false;
      return;
    }
    pullSchedule();
  });

  // 初始化小组件服务
  ScheduleWidgetService.init();

  // 启动日程监控定时器
  startScheduleMonitor();
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

/// 最后一次更新课表时间
final Signal<DateTime?> lastScheduleUpdateTimeSignal = signal(null);

// 事件检查定时器
Timer? _scheduleCheckTimer;

bool pullScheduleLock = false;

/// 从学校配置拉取课表
Future<bool> pullSchedule() async {
  try {
    final school = currentSchoolSignal.value;
    final semester = currentSemesterSignal.value;

    if (pullScheduleLock) throw Exception('Pull schedule locked');
    pullScheduleLock = true;
    final scheduleService = school?.scheduleServices;
    if (scheduleService == null) throw Exception('No schedule service');
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

/// 启动日程状态监控
void startScheduleMonitor() {
  // 取消已存在的定时器，防止重复
  _scheduleCheckTimer?.cancel();

  // 立即执行一次更新
  _checkAndUpdateCurrentSchedule();

  // 启动周期性定时器
  _scheduleCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
    _checkAndUpdateCurrentSchedule();
    ScheduleWidgetService.updateWidget();
  });
}

/// 停止监控
void stopScheduleMonitor() {
  _scheduleCheckTimer?.cancel();
  _scheduleCheckTimer = null;
}

/// 核心检查与更新逻辑
void _checkAndUpdateCurrentSchedule() {
  final semester = currentSemesterSignal.value;
  final school = currentSchoolSignal.value;
  final index = calendarEventIndexSignal.value;
  final eventMap = {
    ...scheduleBaseEventsSignal.value.asMap(),
    ...scheduleCustomEventsSignal.value.asMap(),
  };

  // 如果学期信息或学校服务未就绪，清空状态
  if (semester == null || school == null) {
    currentActiveEventSignal.value = null;
    nextUpcomingEventSignal.value = null;
    todayRemainingEventsSignal.value = [];
    return;
  }

  final slots = school.scheduleServices.slots;
  final now = DateTime.now();

  // 获取当前和下一事件
  final current = getCurrentEvent(
    time: now,
    index: index,
    eventMap: eventMap,
    slots: slots,
    semester: semester,
  );

  final next = getNextEvent(
    time: now,
    index: index,
    eventMap: eventMap,
    slots: slots,
    semester: semester,
  );

  final remainingList = getRemainingEvents(
    time: now,
    index: index,
    eventMap: eventMap,
    slots: slots,
    semester: semester,
  );

  // 更新全局状态
  currentActiveEventSignal.value = current;
  nextUpcomingEventSignal.value = next;
  todayRemainingEventsSignal.value = remainingList;
}
