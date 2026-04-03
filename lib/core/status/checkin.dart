import 'package:punklorde/core/account/utils.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:signals/signals_flutter.dart';

/// 全局传递的签到身份凭证GUID
final Signal<Set<String>> checkinAuthSignal = Signal({});

/// 初始化签到身份凭证
void initCheckinAuth(List<AuthCredential> credentials) {
  checkinAuthSignal.value = credentials
      .map((v) => genAuthCredentialGuid(v))
      .toSet();
}
