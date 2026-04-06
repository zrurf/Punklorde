import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/semester.dart';
import 'package:punklorde/module/platform/cqupt/academic_portal.dart';
import 'package:punklorde/module/school/cqupt/api/client.dart';
import 'package:punklorde/module/school/cqupt/utils/schedule_parser.dart';
import 'package:punklorde/module/school/cqupt/view/widget/schedule_event.dart';

class CquptScheduleService extends ScheduleService {
  final CquptApiClient _apiClient = CquptApiClient();

  @override
  List<TimeSlot> get slots => const [
    TimeSlot(index: 1, name: '上午第1节', startMinutes: 480, endMinutes: 525),
    TimeSlot(index: 2, name: '上午第2节', startMinutes: 535, endMinutes: 580),
    TimeSlot(index: 3, name: '上午第3节', startMinutes: 615, endMinutes: 660),
    TimeSlot(index: 4, name: '上午第4节', startMinutes: 670, endMinutes: 715),
    TimeSlot(index: 5, name: '下午第5节', startMinutes: 840, endMinutes: 885),
    TimeSlot(index: 6, name: '下午第6节', startMinutes: 895, endMinutes: 940),
    TimeSlot(index: 7, name: '下午第7节', startMinutes: 975, endMinutes: 1020),
    TimeSlot(index: 8, name: '下午第8节', startMinutes: 1030, endMinutes: 1075),
    TimeSlot(index: 9, name: '晚上第9节', startMinutes: 1140, endMinutes: 1185),
    TimeSlot(index: 10, name: '晚上第10节', startMinutes: 1195, endMinutes: 1240),
    TimeSlot(index: 11, name: '晚上第11节', startMinutes: 1250, endMinutes: 1295),
    TimeSlot(index: 12, name: '晚上第12节', startMinutes: 1305, endMinutes: 1350),
  ];

  @override
  AuthCredential? getCredential() {
    return authManager.getPrimaryAuthByPlatform(platCquptAcademicPortal.id);
  }

  @override
  Future<List<ScheduleEvent>?> getBaseEvents(
    Semester semester,
    AuthCredential credential,
  ) async {
    if (credential.type != platCquptAcademicPortal.id) return null;
    final scheduleResp = await _apiClient.getSchedule(credential.id);
    final examResp = await _apiClient.getExam(credential.id);
    if (scheduleResp == null || examResp == null) return null;
    return [
      ...parseScheduleHtml(scheduleResp) ?? [],
      ...parseExamHtml(examResp) ?? [],
    ];
  }

  @override
  void openEventDetail(BuildContext context, ScheduleEvent event) {
    showFSheet(
      context: context,
      builder: (sheetContext) =>
          ScheduleEventPanel(event: event, service: this),
      side: .btt,
    );
  }
}
