/// 签到类型
enum RollcallType {
  qr, // 二维码
  pin, // 数字签到码
  radar, // 雷达
}

/// 签到事件
class RollcallModel {
  final String id;
  final String? state;
  final String? title;
  final String? author;
  final String? dept;
  final RollcallType type;
  final String status;
  final bool isExpired;
  final bool isScored;

  RollcallModel({
    required this.id,
    required this.state,
    required this.title,
    required this.author,
    required this.dept,
    required this.type,
    required this.status,
    required this.isExpired,
    required this.isScored,
  });

  factory RollcallModel.fromJson(Map<String, dynamic> json) {
    late final RollcallType type;
    if (json['is_number']) {
      type = RollcallType.pin;
    } else if (json['is_radar']) {
      type = RollcallType.radar;
    } else {
      type = RollcallType.qr;
    }

    return RollcallModel(
      id: json['rollcall_id'],
      state: json['rollcall_status'],
      title: json['course_title'],
      author: json['created_by_name'],
      dept: json['department_name'],
      type: type,
      status: json['status'],
      isExpired: json['is_expired'] ?? false,
      isScored: json['scored'] ?? false,
    );
  }

  bool isDone() => status == "on_call" || status == "on_call_fine";
}
