import 'package:punklorde/module/model/auth.dart';
import 'package:signals/signals_flutter.dart';

/// 全局传递的签到身份凭证
final Signal<Set<AuthCredential>> checkinAuthSignal = Signal({});

/// 初始化签到身份凭证
void initCheckinAuth(List<AuthCredential> credentials) {
  checkinAuthSignal.value = credentials.toSet();
}
