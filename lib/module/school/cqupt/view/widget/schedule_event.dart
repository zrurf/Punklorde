import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/utils/etc/time.dart';

class ScheduleEventPanel extends StatefulWidget {
  final ScheduleService service;
  final ScheduleEvent event;

  const ScheduleEventPanel({
    super.key,
    required this.service,
    required this.event,
  });

  @override
  State<StatefulWidget> createState() => _ScheduleEventPanelState();
}

class _ScheduleEventPanelState extends State<ScheduleEventPanel> {
  final weekLabels = [
    t.label.calender_mon,
    t.label.calender_tue,
    t.label.calender_wed,
    t.label.calender_thu,
    t.label.calender_fri,
    t.label.calender_sat,
    t.label.calender_sun,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final ev = widget.event;
    final slots = widget.service.slots;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          height: .infinity,
          width: .infinity,
          decoration: BoxDecoration(
            color: colors.background,
            border: .symmetric(horizontal: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            padding: const .symmetric(horizontal: 16, vertical: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Column(
                  spacing: 8,
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      ev.location ?? "",
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.mutedForeground,
                        fontWeight: .w600,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: .bold,
                          color: colors.foreground,
                        ),
                        children: [
                          TextSpan(text: ev.title),
                          if (ev.ext?["exam"] == true)
                            WidgetSpan(
                              alignment: .middle,
                              child: FBadge(
                                child: Text(
                                  t.label.exam,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ev.description ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    Column(
                      spacing: 12,
                      children: [
                        (ev.ext?.containsKey("teacher") ?? false)
                            ? _buildField(
                                LucideIcons.graduationCap,
                                t.title.teacher,
                                ev.ext!["teacher"],
                              )
                            : null,
                        (ev.ext?.containsKey("id") ?? false)
                            ? _buildField(
                                LucideIcons.notebookText,
                                t.title.course_id,
                                ev.ext!["id"],
                              )
                            : null,
                        (ev.ext?.containsKey("classId") ?? false)
                            ? _buildField(
                                LucideIcons.notebook,
                                t.title.class_id,
                                ev.ext!["classId"],
                              )
                            : null,
                        _buildField(
                          LucideIcons.clockFading,
                          t.title.time,
                          "${formatWeeks(ev.activeWeeks ?? [])} ${(ev.activeDay != null) ? weekLabels[ev.activeDay! - 1] : ''} ${formatDayMinutes(ev.relativeStartMinutes ?? slots[ev.timeSlotIndex! - 1].startMinutes)}-${formatDayMinutes(ev.relativeEndMinutes ?? slots[ev.timeSlotIndex! + ev.timeSlotCount! - 2].endMinutes)}",
                        ),
                        (ev.ext?.containsKey("pos") ?? false)
                            ? _buildField(
                                LucideIcons.info,
                                t.title.exam_position,
                                ev.ext!["pos"],
                              )
                            : null,
                        (ev.ext?.containsKey("classId") ?? false)
                            ? FButton(
                                variant: .ghost,
                                size: .sm,
                                child: Text(
                                  t.action.check_stu_list,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colors.primary,
                                  ),
                                ),
                                onPress: () {
                                  context.push(
                                    '/feat/cqupt/global/stulist/${ev.ext!["classId"]}',
                                  );
                                },
                              )
                            : null,
                      ].nonNulls.toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String title, String value) {
    final colors = context.theme.colors;
    return Row(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.primary),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: colors.foreground),
            softWrap: true,
            overflow: .visible,
            textAlign: .right,
          ),
        ),
      ],
    );
  }
}
