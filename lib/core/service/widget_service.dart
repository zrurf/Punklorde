import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/schedule.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/utils/schedule.dart';
import 'package:signals/signals_flutter.dart';

class ScheduleWidgetService {
  static const String _androidWidgetName =
      'hacker.silverwolf.punklorde.ScheduleWidgetReceiver';

  static const _channel = MethodChannel(
    'hacker.silverwolf.punklorde/widget_refresh',
  );

  static void init() {
    effect(() {
      final _ = calendarEventIndexSignal.value;
      final __ = currentSemesterSignal.value;
      final ___ = currentSchoolSignal.value;
      final ____ = scheduleBaseEventsSignal.value;
      final _____ = scheduleCustomEventsSignal.value;
      Future.microtask(() => updateWidget());
    });
  }

  static Future<void> updateWidget() async {
    try {
      final semester = currentSemesterSignal.value;
      final scheduleService = currentSchoolSignal.value?.scheduleServices;
      final index = calendarEventIndexSignal.value;

      if (semester == null || scheduleService == null) {
        await _clearWidgetData();
        return;
      }

      final allEvents = <String, ScheduleEvent>{
        ...scheduleBaseEventsSignal.value.toMap(),
        ...scheduleCustomEventsSignal.value.toMap(),
      };

      final now = DateTime.now();

      // 1. 分别获取当前和下一个事件
      final currentEvent = getCurrentEvent(
        time: now,
        index: index,
        eventMap: allEvents,
        slots: scheduleService.slots,
        semester: semester,
      );

      final nextEvent = getNextEvent(
        time: now,
        index: index,
        eventMap: allEvents,
        slots: scheduleService.slots,
        semester: semester,
      );

      // 2. 根据规则决定最终显示哪个事件
      ScheduleEvent? displayEvent;
      String displayStatus = 'upcoming';

      if (currentEvent == null) {
        // 规则1: 如果当前无事件，则显示下一个事件
        displayEvent = nextEvent;
        displayStatus = 'upcoming';
      } else {
        // 规则2: 如果当前有事件
        if (nextEvent != null) {
          // 计算距离下一事件还有多少分钟
          final minutesUntilNext = _getMinutesUntilNextEvent(
            nextEvent,
            scheduleService.slots,
            now,
          );

          if (minutesUntilNext <= 60) {
            // 距离下一事件 <= 60分钟，显示下一个事件
            displayEvent = nextEvent;
            displayStatus = 'upcoming';
          } else {
            // 距离下一事件 > 60分钟，显示当前事件
            displayEvent = currentEvent;
            displayStatus = 'ongoing';
          }
        } else {
          // 没有下一个事件，继续显示当前事件
          displayEvent = currentEvent;
          displayStatus = 'ongoing';
        }
      }

      // 3. 写入数据
      if (displayEvent != null) {
        final week = semester.getWeekIndex(now);
        final dayNames = [
          t.label.calender_mon,
          t.label.calender_tue,
          t.label.calender_wed,
          t.label.calender_thu,
          t.label.calender_fri,
          t.label.calender_sat,
          t.label.calender_sun,
        ];
        final dayName = dayNames[now.weekday - 1];

        final timeDisplay = _getTimeDisplay(
          displayEvent,
          scheduleService.slots,
        );
        final endTimeDisplay = _getEndTimeDisplay(
          displayEvent,
          scheduleService.slots,
        );
        final colorHex = _colorToHex(displayEvent.color);

        await HomeWidget.saveWidgetData<String>('has_event', 'true');
        await HomeWidget.saveWidgetData<String>(
          'event_title',
          displayEvent.title,
        );
        await HomeWidget.saveWidgetData<String>(
          'event_location',
          displayEvent.location ?? '',
        );
        await HomeWidget.saveWidgetData<String>('event_time', timeDisplay);
        await HomeWidget.saveWidgetData<String>(
          'event_end_time',
          endTimeDisplay,
        );
        await HomeWidget.saveWidgetData<String>(
          'event_week',
          t.title.week_title(week: week),
        );
        await HomeWidget.saveWidgetData<String>('event_day', dayName);
        await HomeWidget.saveWidgetData<String>('event_status', displayStatus);
        await HomeWidget.saveWidgetData<String>('event_color', colorHex);
      } else {
        await _clearWidgetData();
        return;
      }

      await _forceGlanceRefresh();
    } catch (e) {
      print('Update schedule widget failed: $e');
    }
  }

  /// 计算距离下一个事件还有多少分钟
  static int _getMinutesUntilNextEvent(
    ScheduleEvent event,
    List<TimeSlot> slots,
    DateTime now,
  ) {
    int nextStartMinute = 0;
    switch (event.anchor) {
      case ScheduleAnchor.slot:
        if (event.timeSlotIndex != null) {
          final slot = slots
              .where((s) => s.index == event.timeSlotIndex)
              .firstOrNull;
          if (slot != null) nextStartMinute = slot.startMinutes;
        }
        break;
      case ScheduleAnchor.relative:
        nextStartMinute = (event.relativeStartMinutes ?? 0) % 1440;
        break;
      case ScheduleAnchor.absolute:
      case ScheduleAnchor.point:
        if (event.absoluteStart != null) {
          nextStartMinute =
              event.absoluteStart!.hour * 60 + event.absoluteStart!.minute;
        }
        break;
    }

    int currentMinute = now.hour * 60 + now.minute;
    int diff = nextStartMinute - currentMinute;

    // 处理跨天的情况 (例如当前 23:00，下一事件 08:00)
    if (diff < 0) diff += 1440;

    return diff;
  }

  static Future<void> _clearWidgetData() async {
    await HomeWidget.saveWidgetData<String>('has_event', 'false');
    await HomeWidget.saveWidgetData<String>('event_title', '暂无课程');
    await HomeWidget.saveWidgetData<String>('event_location', '');
    await HomeWidget.saveWidgetData<String>('event_time', '');
    await HomeWidget.saveWidgetData<String>('event_end_time', '');
    await HomeWidget.saveWidgetData<String>('event_week', '');
    await HomeWidget.saveWidgetData<String>('event_day', '');
    await HomeWidget.saveWidgetData<String>('event_status', '');
    await HomeWidget.saveWidgetData<String>('event_color', 'FF6200EE');

    await _forceGlanceRefresh();
  }

  static String _getTimeDisplay(ScheduleEvent event, List<TimeSlot> slots) {
    switch (event.anchor) {
      case ScheduleAnchor.slot:
        if (event.timeSlotIndex == null) return '';
        final slot = slots
            .where((s) => s.index == event.timeSlotIndex)
            .firstOrNull;
        if (slot == null) return '';
        return _minutesToTime(slot.startMinutes);
      case ScheduleAnchor.relative:
        if (event.relativeStartMinutes == null) return '';
        return _minutesToTime(event.relativeStartMinutes! % 1440);
      case ScheduleAnchor.absolute:
      case ScheduleAnchor.point:
        if (event.absoluteStart == null) return '';
        final date = event.absoluteStart!.toLocal();
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  static String _getEndTimeDisplay(ScheduleEvent event, List<TimeSlot> slots) {
    switch (event.anchor) {
      case ScheduleAnchor.slot:
        if (event.timeSlotIndex == null) return '';
        final count = event.timeSlotCount ?? 1;
        final endIndex = event.timeSlotIndex! + count - 1;
        final slot = slots.where((s) => s.index == endIndex).firstOrNull;
        if (slot == null) return '';
        return _minutesToTime(slot.endMinutes);
      case ScheduleAnchor.relative:
        if (event.relativeEndMinutes == null) return '';
        return _minutesToTime(event.relativeEndMinutes! % 1440);
      case ScheduleAnchor.absolute:
        if (event.absoluteEnd == null) return '';
        final date = event.absoluteEnd!.toLocal();
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      case ScheduleAnchor.point:
        return '';
    }
  }

  static String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String _colorToHex(int? color) {
    if (color == null) return 'FF6200EE';
    return color.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  // 核心强制刷新方法
  static Future<void> _forceGlanceRefresh() async {
    try {
      // 通过 MethodChannel 直接调用 Native 的 ScheduleAppWidget().updateAll()
      await _channel.invokeMethod('forceRefresh');
    } catch (e) {
      print('Force refresh widget failed: $e');
    }
  }
}
