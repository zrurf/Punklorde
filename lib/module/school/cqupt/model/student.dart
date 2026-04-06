/// 学生信息结构体
class StudentInfo {
  final String studentId; // 学号
  final String name; // 姓名
  final String? gender; // 性别
  final String? className; // 班级
  final String? majorId; // 专业号
  final String? majorName; // 专业名
  final String? college; // 学院
  final String? grade; // 年级
  final String? studentStatus; // 学籍状态

  // 选课名单特有字段
  final String? courseSelectionStatus; // 选课状态
  final String? courseCategory; // 课程类别

  // 特殊考试名单特有字段
  final String? examType; // 考试类型
  final String? reviewStatus; // 审核状态

  const StudentInfo({
    required this.studentId,
    required this.name,
    this.gender,
    this.className,
    this.majorId,
    this.majorName,
    this.college,
    this.grade,
    this.studentStatus,
    this.courseSelectionStatus,
    this.courseCategory,
    this.examType,
    this.reviewStatus,
  });
}
