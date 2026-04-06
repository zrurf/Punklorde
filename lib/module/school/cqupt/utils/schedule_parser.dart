import 'dart:convert';

import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:punklorde/app/theme/schedule.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/school/cqupt/model/student.dart';
import 'package:xxh3/xxh3.dart';

/// Parsing function for schedule HTML.
///
/// Extracts base schedule events and alteration events (cancel/add) from the provided HTML string.
/// Returns null if a critical error occurs during parsing.
List<ScheduleEvent>? parseScheduleHtml(String htmlData) {
  try {
    final document = parser.parse(htmlData);
    final List<ScheduleEvent> events = [];

    // 1. Parse Base Schedule (from List View for robustness)
    final listTable = document.querySelector('#kbStuTabs-list table');
    if (listTable != null) {
      events.addAll(_parseListTable(listTable));
    }

    // 2. Parse Alterations (Cancel/Add)
    final alterTable = document.querySelector('#kbStuTabs-ttk table');
    if (alterTable != null) {
      events.addAll(_parseAlterTable(alterTable));
    }

    return events;
  } catch (e) {
    // Log error if needed
    return null;
  }
}

/// 解析考试安排 HTML
///
/// 提取考试信息并转换为 ScheduleEvent 列表。
/// 使用时间槽锚点，并将具体的开始结束时间（距当天0点的分钟数）存储在ext中。
List<ScheduleEvent>? parseExamHtml(String htmlData) {
  try {
    final document = parser.parse(htmlData);
    final List<ScheduleEvent> events = [];

    final table = document.querySelector('table');
    if (table == null) return null;

    final rows = table.querySelectorAll('tr');
    if (rows.length <= 1) return events;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final cells = row.querySelectorAll('td');

      if (cells.length < 12) continue;

      // 1. 基础信息提取
      final courseName = cells[5].text.trim();
      final courseId = cells[4].text.trim();
      final examType = cells[3].text.trim();
      final weekStr = cells[6].text.trim(); // e.g., "9周"
      final dayStr = cells[7].text.trim(); // e.g., "1"
      final timeStr = cells[8].text.trim(); // e.g., "第7-8节 16:10-18:10"
      final location = cells[9].text.trim();
      final seat = cells[10].text.trim();
      final status = cells[11].text.trim();
      final studentName = cells[2].text.trim();

      // 2. 周次解析
      final weekMatch = RegExp(r'(\d+)').firstMatch(weekStr);
      final week = weekMatch != null ? int.tryParse(weekMatch.group(1)!) : null;
      if (week == null) continue;

      // 3. 星期解析
      final day = int.tryParse(dayStr);
      if (day == null || day < 1 || day > 7) continue;

      // 4. 时间槽解析 (处理 "第n节" 或 "第n-m节")
      int slotIndex = 0;
      int slotCount = 1;

      final slotRegex = RegExp(r'第(\d+)(?:-(\d+))?节');
      final slotMatch = slotRegex.firstMatch(timeStr);

      if (slotMatch != null) {
        final startSlot = int.parse(slotMatch.group(1)!);
        final endSlot = slotMatch.group(2) != null
            ? int.parse(slotMatch.group(2)!)
            : startSlot;

        slotIndex = startSlot;
        slotCount = endSlot - startSlot + 1;
      }

      // 5. 具体时间解析 (计算距0点分钟数)
      int? startMinutes;
      int? endMinutes;

      final timeRegex = RegExp(r'(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
      final timeMatch = timeRegex.firstMatch(timeStr);

      if (timeMatch != null) {
        final startH = int.parse(timeMatch.group(1)!);
        final startM = int.parse(timeMatch.group(2)!);
        final endH = int.parse(timeMatch.group(3)!);
        final endM = int.parse(timeMatch.group(4)!);

        startMinutes = startH * 60 + startM;
        endMinutes = endH * 60 + endM;
      }

      // 6. 构建 Ext Map
      final ext = <String, dynamic>{
        'id': courseId,
        'status': status,
        'type': examType,
        'pos': seat,
        'name': studentName,
        'exam': true,
      };

      // 7. 生成确定性 ID
      final id = 'exam_${courseId}_${week}_$day';

      // 8. 创建 ScheduleEvent
      events.add(
        ScheduleEvent(
          id: id,
          type: ScheduleEventType.base,
          anchor: ScheduleAnchor.slot,
          title: '考试 $courseName',
          description: "$examType $courseName",
          location: location,
          activeWeeks: [week],
          activeDay: day,
          timeSlotIndex: slotIndex,
          timeSlotCount: slotCount,
          relativeStartMinutes: startMinutes,
          relativeEndMinutes: endMinutes,
          color: ScheduleTheme.hilightedColor,
          ext: ext,
        ),
      );
    }

    return events;
  } catch (e) {
    return null;
  }
}

/// Helper to parse the main schedule list table.
List<ScheduleEvent> _parseListTable(dom.Element table) {
  final List<ScheduleEvent> events = [];
  final rows = table.querySelectorAll('tr');

  // Skip header row
  if (rows.isEmpty) return events;

  // Rowspan buffer: stores the content of cells that span multiple rows.
  // Index corresponds to column index.
  // Value is a record: (content, remainingSpan)
  List<(String, int)> rowSpanBuffer = List.filled(10, ('', 0));

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    final cells = row.querySelectorAll('td');

    // Reconstruct the logical row using the buffer and actual cells
    List<String> currentRowData = [];
    int cellIndex = 0;

    for (int col = 0; col < 10; col++) {
      // Check if buffer has content for this column
      if (rowSpanBuffer[col].$2 > 0) {
        currentRowData.add(rowSpanBuffer[col].$1);
        rowSpanBuffer[col] = (rowSpanBuffer[col].$1, rowSpanBuffer[col].$2 - 1);
      } else {
        // Take from current cell
        if (cellIndex < cells.length) {
          final cell = cells[cellIndex];
          final text = cell.text.trim();
          currentRowData.add(text);

          // Handle rowspan
          final spanAttr = cell.attributes['rowspan'];
          int span = 1;
          if (spanAttr != null) {
            span = int.tryParse(spanAttr) ?? 1;
          }
          if (span > 1) {
            rowSpanBuffer[col] = (text, span - 1);
          }
          cellIndex++;
        } else {
          currentRowData.add('');
        }
      }
    }

    // Check if this row actually contains valid course data
    // Col 1 is Course ID-Name, Col 2 is Class ID
    if (currentRowData.length < 8 || currentRowData[1].isEmpty) {
      continue;
    }

    // Extract and create event
    final event = _createEventFromRow(currentRowData);
    if (event != null) {
      events.add(event);
    }
  }

  return events;
}

/// Creates a ScheduleEvent from a parsed row of the list table.
ScheduleEvent? _createEventFromRow(List<String> data) {
  // Indices based on visual analysis:
  // 0: Type (教学班分类)
  // 1: Course ID - Name (课程号-课程名)
  // 2: Class ID (教学班)
  // 3: Category (类别)
  // 4: Status (选课状态)
  // 5: Teacher (教师)
  // 6: Time (上课时间)
  // 7: Location (地点)
  // 8: Student List (ignored)
  // 9: Remark (ignored)

  final rawName = data[1];
  final parts = rawName.split('-');

  String courseId = '';
  String courseName = rawName;

  // Robust splitting: assume first part is ID if format matches
  if (parts.length >= 2) {
    // Check if first part looks like a code (alphanumeric)
    if (RegExp(r'^[A-Z0-9]+$').hasMatch(parts[0])) {
      courseId = parts[0];
      courseName = parts.sublist(1).join('-');
    }
  }

  final timeStr = data[6];
  final location = data[7];

  // Parse Time: "星期1第3-4节 1-16周"
  final timeInfo = _parseSlotTime(timeStr);
  if (timeInfo == null) return null; // Skip if time parsing fails

  // Ext data
  final ext = {
    'id': courseId,
    'type': data[0],
    'category': data[3],
    'status': data[4],
    'teacher': data[5],
    'classId': data[2],
  };

  // Generate Deterministic ID
  // ID = classId + day + slotIndex
  final String id =
      'base_${data[0]}_${data[1]}_${data[2]}_${data[3]}_${data[4]}_${data[5]}_${data[6]}_${data[7]}_${timeInfo.day}_${timeInfo.slotIndex}_${timeInfo.slotCount}';

  return ScheduleEvent(
    id: "base_${xxh3String(utf8.encode(id))}",
    description: "${data[0]} ${data[3]} ${data[4]}",
    type: ScheduleEventType.base,
    anchor: ScheduleAnchor.slot,
    activeDay: timeInfo.day,
    timeSlotIndex: timeInfo.slotIndex,
    timeSlotCount: timeInfo.slotCount,
    activeWeeks: timeInfo.weeks,
    title: courseName,
    location: location,
    color: ScheduleTheme.primaryColor,
    ext: ext,
  );
}

/// Helper to parse alteration table.
List<ScheduleEvent> _parseAlterTable(dom.Element table) {
  final List<ScheduleEvent> events = [];
  final rows = table.querySelectorAll('tr');

  // Skip header
  for (int i = 1; i < rows.length; i++) {
    final cells = rows[i].querySelectorAll('td');
    if (cells.length < 7) continue;

    // Columns:
    // 0: Seq (序号)
    // 1: Semester
    // 2: Type (类型: 补课/停课)
    // 3: Class ID (教学班)
    // 4: Course Name (课程名称)
    // 5: Teacher (教师)
    // 6: Cancel Week (停课周)
    // 7: Cancel Time (停课时段)
    // 8: Add Time (补(代)课时间)
    // 9: Add Location (补课地点)
    // 10: Sub Teacher (代课老师)

    final seq = cells[0].text.trim();
    final typeStr = cells[2].text.trim();
    final classId = cells[3].text.trim();
    final courseName = cells[4].text.trim();
    final teacher = cells[5].text.trim();

    final ext = {'classId': classId, 'teacher': teacher};

    if (typeStr.contains('停课')) {
      final cancelWeekStr = cells[6].text.trim(); // e.g., "3周"
      final cancelTimeStr = cells[7].text.trim(); // e.g., "星期5第5-6节"

      final weeks = _parseSimpleWeeks(cancelWeekStr);
      final timeInfo = _parseSlotTime(cancelTimeStr);

      if (timeInfo != null && weeks.isNotEmpty) {
        events.add(
          ScheduleEvent(
            id: 'alter_${seq}_cancel',
            type: ScheduleEventType.cancel,
            anchor: ScheduleAnchor.slot,
            activeDay: timeInfo.day,
            timeSlotIndex: timeInfo.slotIndex,
            timeSlotCount: timeInfo.slotCount,
            activeWeeks: weeks,
            title: '$courseName (停)',
            description: '停课',
            color: ScheduleTheme.mutedColor,
            ext: ext,
          ),
        );
      }
    } else if (typeStr.contains('补课')) {
      final addTimeStr = cells[8].text.trim(); // e.g., "5周星期1第7-8节"
      final addLocation = cells[9].text.trim();

      // This string contains both week and time
      final addInfo = _parseAlterTime(addTimeStr);

      if (addInfo != null) {
        events.add(
          ScheduleEvent(
            id: 'alter_${seq}_add',
            type: ScheduleEventType.add,
            anchor: ScheduleAnchor.slot,
            activeDay: addInfo.day,
            timeSlotIndex: addInfo.slotIndex,
            timeSlotCount: addInfo.slotCount,
            activeWeeks: addInfo.weeks,
            title: '$courseName (补)',
            location: addLocation,
            description: '补课',
            color: ScheduleTheme.boldColor,
            ext: ext,
          ),
        );
      }
    }
  }
  return events;
}

/// Data class for parsed slot time info
class _SlotTimeInfo {
  final int day;
  final int slotIndex;
  final int slotCount;
  final List<int> weeks;
  _SlotTimeInfo(this.day, this.slotIndex, this.slotCount, this.weeks);
}

/// Parses time strings like "星期1第3-4节 1-16周"
_SlotTimeInfo? _parseSlotTime(String text) {
  // Regex for day and slot
  // Allow flexible spaces
  final dayRegex = RegExp(r'星期(\d)');
  final slotRegex = RegExp(
    r'第(\d+)-(\d+)节',
  ); // Assuming ranges, can adapt for single

  final dayMatch = dayRegex.firstMatch(text);
  final slotMatch = slotRegex.firstMatch(text);

  if (dayMatch == null || slotMatch == null) return null;

  final day = int.parse(dayMatch.group(1)!);
  final startSlot = int.parse(slotMatch.group(1)!);
  final endSlot = int.parse(slotMatch.group(2)!);

  // Week parsing
  final weeks = _parseWeeks(text);

  return _SlotTimeInfo(day, startSlot, endSlot - startSlot + 1, weeks);
}

/// Parses time strings for alterations, e.g., "5周星期1第7-8节"
_SlotTimeInfo? _parseAlterTime(String text) {
  // Regex to find week number at the start or mixed
  final weekRegex = RegExp(r'(\d+)周');
  final dayRegex = RegExp(r'星期(\d)');
  final slotRegex = RegExp(r'第(\d+)-(\d+)节');

  final weekMatch = weekRegex.firstMatch(text);
  final dayMatch = dayRegex.firstMatch(text);
  final slotMatch = slotRegex.firstMatch(text);

  if (weekMatch == null || dayMatch == null || slotMatch == null) return null;

  final week = int.parse(weekMatch.group(1)!);
  final day = int.parse(dayMatch.group(1)!);
  final startSlot = int.parse(slotMatch.group(1)!);
  final endSlot = int.parse(slotMatch.group(2)!);

  return _SlotTimeInfo(day, startSlot, endSlot - startSlot + 1, [week]);
}

/// Parses week strings like "1-16周", "1-5周单周", "1-6周,8-16周"
List<int> _parseWeeks(String text) {
  final List<int> weeks = [];
  // Find all patterns like "1-16周", "1周", "1-5周单周"
  final weekPattern = RegExp(r'(\d+)-(\d+)周(单|双)?|(\d+)周');

  for (final match in weekPattern.allMatches(text)) {
    if (match.group(4) != null) {
      // Single week: "5周"
      weeks.add(int.parse(match.group(4)!));
    } else {
      // Range: "1-16周" or "1-5周单周"
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2)!);
      final mod = match.group(3); // '单' or '双'

      for (int w = start; w <= end; w++) {
        if (mod == '单' && w % 2 != 0) {
          weeks.add(w);
        } else if (mod == '双' && w % 2 == 0) {
          weeks.add(w);
        } else if (mod == null) {
          weeks.add(w);
        }
      }
    }
  }

  // Remove duplicates and sort (though logic shouldn't produce dupes usually)
  return weeks.toSet().toList()..sort();
}

/// Helper for simple week string like "3周"
List<int> _parseSimpleWeeks(String text) {
  final match = RegExp(r'(\d+)周').firstMatch(text);
  if (match != null) {
    return [int.parse(match.group(1)!)];
  }
  return [];
}

/// 解析选课学生名单 HTML
///
/// 提取常规选课名单和特殊考试名单（重修免修等）。
/// 返回学生信息列表，如果发生解析异常则返回 null。
List<StudentInfo>? parseStudentListHtml(String htmlData) {
  try {
    final document = parser.parse(htmlData);
    final List<StudentInfo> students = [];

    // 获取所有表格
    final tables = document.querySelectorAll('table');
    if (tables.isEmpty) return null;

    // 1. 解析第一个表格：选课学生名单
    // 表头：No., 学号, 姓名, 性别, 班级, 专业号, 专业名, 学院, 年级, 学籍状态, 选课状态, 课程类别
    if (tables.isNotEmpty) {
      final rows = tables[0].querySelectorAll('tr');
      // 跳过表头
      for (int i = 1; i < rows.length; i++) {
        final cells = rows[i].querySelectorAll('td');
        // 确保列数足够 (至少12列)
        if (cells.length < 12) continue;

        final student = StudentInfo(
          studentId: cells[1].text.trim(),
          name: cells[2].text.trim(),
          gender: cells[3].text.trim(),
          className: cells[4].text.trim(),
          majorId: cells[5].text.trim(),
          majorName: cells[6].text.trim(),
          college: cells[7].text.trim(),
          grade: cells[8].text.trim(),
          studentStatus: cells[9].text.trim(),
          courseSelectionStatus: cells[10].text.trim(),
          courseCategory: cells[11].text.trim(),
        );
        students.add(student);
      }
    }

    // 2. 解析第二个表格：特殊考试名单
    // 表头：No., 考试类型, 学号, 姓名, 班级, 专业名, 学院, 年级, 学籍状态, 审核状态
    if (tables.length >= 2) {
      final rows = tables[1].querySelectorAll('tr');
      for (int i = 1; i < rows.length; i++) {
        final cells = rows[i].querySelectorAll('td');
        // 确保列数足够 (至少10列)
        if (cells.length < 10) continue;

        final student = StudentInfo(
          examType: cells[1].text.trim(),
          studentId: cells[2].text.trim(),
          name: cells[3].text.trim(),
          className: cells[4].text.trim(),
          majorName: cells[5].text.trim(),
          college: cells[6].text.trim(),
          grade: cells[7].text.trim(),
          studentStatus: cells[8].text.trim(),
          reviewStatus: cells[9].text.trim(),
        );
        students.add(student);
      }
    }

    return students;
  } catch (e) {
    // 发生异常返回 null
    return null;
  }
}
