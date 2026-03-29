import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';

/// 签到类型
enum CheckinType {
  scan, // 扫码
  position, // 位置
  pin, // 数字签到码
  gesture, // 手势
  other, // 其他
}

/// 签到事件
class CheckinEvent {
  final String id;
  final Platform platform;
  final CheckinType type;
  final String name;
  final String? desc;
  final bool done;
  final Future<void> Function(Set<AuthCredential> creds) onCall;

  const CheckinEvent({
    required this.id,
    required this.platform,
    required this.type,
    required this.name,
    this.desc,
    required this.done,
    required this.onCall,
  });
}
