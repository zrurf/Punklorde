import 'package:punklorde/module/feature/chaoxing/model/common.dart';

enum ChaoxingCheckinType {
  normal, // 普通签到
  qr, // 二维码签到
  gesture, // 手势签到
  location, // 位置签到
  code, // 签到码签到
}

/// 签到事件
class ChaoxingCheckin {
  final String title;
  final String desc;
  final ActiveType activeType;
  final ChaoxingCheckinType type;
  final String signId;
  final String classId;
  final String courseId;
  final DateTime startTime;
  final DateTime? endTime;

  const ChaoxingCheckin({
    required this.title,
    required this.desc,
    required this.activeType,
    required this.type,
    required this.signId,
    required this.classId,
    required this.courseId,
    required this.startTime,
    this.endTime,
  });

  factory ChaoxingCheckin.fromActive(
    ActiveResult active,
    String classId,
    String courseId,
    String courseName,
  ) {
    return ChaoxingCheckin(
      title: active.title,
      activeType: active.getActiveType,
      desc: courseName,
      type: switch (active.otherId) {
        "0" => .normal,
        "2" => .qr,
        "3" => .gesture,
        "4" => .location,
        "5" => .code,
        _ => .normal,
      },
      signId: active.id.toString(),
      classId: classId,
      courseId: courseId,
      startTime: active.startTime ?? DateTime.now(),
      endTime: active.endTime,
    );
  }
}
