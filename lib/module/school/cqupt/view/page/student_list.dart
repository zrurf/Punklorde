import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/school/cqupt/api/client.dart';
import 'package:punklorde/module/school/cqupt/model/student.dart';
import 'package:signals/signals_flutter.dart';

/// 选课用户页面
class StudentListPage extends StatefulWidget {
  final String? id;

  const StudentListPage({super.key, required this.id});

  @override
  State<StatefulWidget> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final Signal<List<StudentInfo>?> studentList = signal(null);
  final Signal<bool> isError = signal(false);

  final CquptApiClient _apiClient = CquptApiClient();

  Future<bool> loadData() async {
    final cred = currentSchoolSignal.value?.scheduleServices.getCredential();
    if (cred == null) return false;
    final stuList = await _apiClient.getStudentList(widget.id as String, cred);
    if (stuList == null) return false;
    studentList.value = stuList;
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.id == null) {
      isError.value = true;
      return;
    }
    loadData().then((value) {
      isError.value = !value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header 不依赖 signal，不会因数据变化重建
            FHeader.nested(
              title: Text(t.title.student_list),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            // 表格区域独立组件，隔离 signal 重建范围
            Expanded(
              child: _TableBody(studentList: studentList, isError: isError),
            ),
          ],
        ),
      ),
    );
  }
}

/// 表格内容——独立组件，signal 变更只重建此区域
class _TableBody extends StatelessWidget {
  final Signal<List<StudentInfo>?> studentList;
  final Signal<bool> isError;

  const _TableBody({required this.studentList, required this.isError});

  // ---- 列宽常量 ----
  static const double _wName = 80;
  static const double _wId = 120;
  static const double _wGender = 56;
  static const double _wClass = 110;
  static const double _wMajor = 140;
  static const double _wCollege = 160;
  static const double _wStatus = 160;
  static const double _divider = 1.0;
  static const double _totalWidth =
      _wName +
      _wId +
      _wGender +
      _wClass +
      _wMajor +
      _wCollege +
      _wStatus +
      6 * _divider;
  static const double _rowHeight = 52.0;
  static const double _headerHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final students = studentList.watch(context);
    final error = isError.watch(context);

    // ---- 加载 / 错误态 ----
    if (students == null) {
      return error
          ? Center(
              child: Text(
                t.notice.failed_get_data,
                style: TextStyle(fontSize: 20, color: colors.error),
              ),
            )
          : Center(
              child: FCircularProgress(
                size: .xl,
                style: .delta(iconStyle: .delta(color: colors.primary)),
              ),
            );
    }

    // ---- 表格主体 ----
    // 水平滚动只包外层，垂直滚动用 ListView.builder 实现虚拟化
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _totalWidth,
        child: Column(
          children: [
            // 固定表头
            _buildHeader(colors),
            // 虚拟化数据列表
            Expanded(
              child: Material(
                color: colors.card,
                elevation: 2,
                child: ClipRRect(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemExtent: _rowHeight,
                    // 预构建视口外 8 行
                    cacheExtent: _rowHeight * 8,
                    padding: EdgeInsets.zero,
                    itemBuilder: (_, index) {
                      return RepaintBoundary(
                        child: _buildRow(students[index], colors),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 表头 ----
  Widget _buildHeader(FColors colors) {
    const headers = ['姓名', '学号', '性别', '班级', '专业', '学院', '状态'];
    const widths = [
      _wName,
      _wId,
      _wGender,
      _wClass,
      _wMajor,
      _wCollege,
      _wStatus,
    ];
    const rightAlign = [false, true, false, false, false, false, false];

    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++) ...[
            SizedBox(
              width: widths[i],
              child: Align(
                alignment: rightAlign[i]
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    headers[i],
                    textAlign: rightAlign[i] ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.foreground as Color?,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- 数据行 ----
  Widget _buildRow(StudentInfo s, FColors colors) {
    final status = _computeStatus(s);
    final statusClr = _statusColor(status);
    final fg = colors.foreground as Color?;
    final muted = colors.mutedForeground as Color?;
    const dataStyle = TextStyle(fontSize: 13);

    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // 姓名
          _dataCell(
            _wName,
            false,
            Text(
              s.name,
              style: dataStyle.copyWith(fontWeight: FontWeight.bold, color: fg),
            ),
          ),
          // 学号
          _dataCell(
            _wId,
            true,
            Text(s.studentId, style: dataStyle.copyWith(color: muted)),
          ),
          // 性别
          _dataCell(
            _wGender,
            false,
            Text(s.gender ?? '-', style: dataStyle.copyWith(color: muted)),
          ),
          // 班级
          _dataCell(
            _wClass,
            false,
            Text(s.className ?? '-', style: dataStyle.copyWith(color: muted)),
          ),
          // 专业
          _dataCell(
            _wMajor,
            false,
            Text(
              s.majorName ?? '-',
              overflow: TextOverflow.ellipsis,
              style: dataStyle.copyWith(color: muted),
            ),
          ),
          // 学院
          _dataCell(
            _wCollege,
            false,
            Text(
              s.college ?? '-',
              overflow: TextOverflow.ellipsis,
              style: dataStyle.copyWith(color: muted),
            ),
          ),
          // 状态/类型
          _dataCell(
            _wStatus,
            false,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusClr.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusClr,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 工具方法 ----

  static Widget _dataCell(double width, bool right, Widget child) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: child,
        ),
      ),
    );
  }

  static String _computeStatus(StudentInfo s) {
    if (s.courseSelectionStatus != null &&
        s.courseSelectionStatus!.isNotEmpty) {
      return s.courseSelectionStatus!;
    }
    if (s.examType != null) {
      return '${s.examType} (${s.reviewStatus ?? "-"})';
    }
    return s.studentStatus ?? '-';
  }

  static Color _statusColor(String status) {
    if (status.contains('重修') || status.contains('自修')) {
      return Colors.orange.shade800;
    }
    if (status.contains('正常') || status.contains('通过')) {
      return Colors.green.shade700;
    }
    if (status.contains('必修')) {
      return Colors.blue.shade700;
    }
    if (status.contains('选修')) {
      return Colors.purple.shade400;
    }
    return Colors.grey.shade700;
  }
}
