import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/data.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:signals/signals_flutter.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late final _loading = dataLoading;

  @override
  void initState() {
    super.initState();
    if (clazzList.value.isEmpty) {
      initStatus();
    }
  }

  Future<void> _loadCourses() async {
    initStatus();
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loading.watch(context);
    final classes = clazzList.watch(context);
    final colors = context.theme.colors;

    if (loading && classes.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 36,
              color: colors.mutedForeground.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              t.submodule.chaoxing.no_courses,
              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (context, index) =>
            _buildClassGroup(context, classes[index]),
      ),
    );
  }

  Widget _buildClassGroup(BuildContext context, ClassData classData) {
    final colors = context.theme.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 班级名头部 — 紧凑设计
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classData.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${classData.courses.length} ${t.submodule.chaoxing.courses}',
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          // 课程列表 — 紧凑卡片
          ...classData.courses.map(
            (course) => _buildCourseItem(context, classData, course),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(
    BuildContext context,
    ClassData classData,
    CourseData course,
  ) {
    final colors = context.theme.colors;

    return GestureDetector(
      onTap: () {
        context.push(
          '/feat/chaoxing/active/${classData.id}/${course.id}/${classData.personalId}'
          '?className=${Uri.encodeComponent(classData.name)}'
          '&courseName=${Uri.encodeComponent(course.name)}',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.bookMarked,
                size: 15,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.teacher.isNotEmpty)
                    Text(
                      course.teacher,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
