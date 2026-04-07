import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/schedule.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/feature.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/school.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:punklorde/utils/schedule.dart';
import 'package:signals/signals_flutter.dart';

final SchoolTab tabSchedule = SchoolTab(
  id: 'common_schedule',
  name: '日程',
  widget: (BuildContext context) {
    final colors = context.theme.colors;
    final events = todayRemainingEventsSignal.watch(context);
    final semester = currentSemesterSignal.watch(context);
    final slots =
        currentSchoolSignal.watch(context)?.scheduleServices.slots ?? [];
    bool isActive = false;
    if (semester != null && events.isNotEmpty) {
      isActive = isEventActive(
        event: events.first,
        time: DateTime.now(),
        semester: semester,
        slots: slots,
      );
    }
    return SizedBox.expand(
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 4),
        child: (events.isNotEmpty)
            ? ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final ev = events[index];
                  return Padding(
                    padding: const .symmetric(vertical: 4),
                    child: _buildEventCard(
                      context,
                      slots,
                      ev,
                      index + (isActive ? 0 : 1),
                    ),
                  );
                },
              )
            : Padding(
                padding: const .all(8),
                child: Column(
                  spacing: 8,
                  children: [
                    Icon(
                      LucideIcons.rockingChair,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      t.notice.schedule_empty,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  },
);

SchoolTab tabFunctions(List<Feature> feats) => SchoolTab(
  id: 'common_func',
  name: '工作台',
  widget: (BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const .symmetric(horizontal: 16),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 80,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: feats.length,
            itemBuilder: (context, index) =>
                _buildFeatBox(context, feats[index]),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
          ),
        ),
      ),
    );
  },
);

Widget _buildFeatBox(BuildContext context, Feature feat) {
  return FTappable(
    onPress: () => feat.action(context),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FTappable(
          child: Container(
            width: 48,
            height: 48,
            padding: .all(8),
            decoration: BoxDecoration(
              color: feat.bgColor,
              borderRadius: .circular(12),
            ),
            child: feat.icon,
          ),
        ),

        const SizedBox(height: 4),
        Text(
          feat.name,
          style: const TextStyle(fontSize: 12),
          softWrap: true,
          overflow: .ellipsis,
          textAlign: .center,
          maxLines: 2,
        ),
      ],
    ),
  );
}

Widget _buildEventCard(
  BuildContext context,
  List<TimeSlot> slots,
  ScheduleEvent event,
  int flag,
) {
  final colors = context.theme.colors;
  return FCard.raw(
    child: Padding(
      padding: const .all(16),
      child: Column(
        spacing: 8,
        crossAxisAlignment: .start,
        children: [
          switch (flag) {
            0 => FBadge(
              child: Text(
                t.label.ongoing,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            1 => FBadge(
              variant: .secondary,
              child: Text(
                t.label.upcoming,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            _ => null,
          },
          Text(
            event.title,
            style: const TextStyle(fontSize: 18, fontWeight: .w600),
            softWrap: true,
          ),
          Row(
            spacing: 4,
            children: [
              Icon(LucideIcons.clockFading, size: 16, color: colors.primary),
              Text(
                "${formatDayMinutes(event.relativeStartMinutes ?? slots[event.timeSlotIndex! - 1].startMinutes)}-${formatDayMinutes(event.relativeEndMinutes ?? slots[event.timeSlotIndex! + event.timeSlotCount! - 2].endMinutes)}",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Row(
            spacing: 4,
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: colors.primary),
              Text(event.location ?? "", style: const TextStyle(fontSize: 14)),
            ],
          ),
        ].nonNulls.toList(),
      ),
    ),
  );
}
