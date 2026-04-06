import 'package:punklorde/module/model/code_handler.dart';

/// 学在重邮签到
class CquptTronCheckinCodeHandler extends CodeHandler {
  @override
  String get id => "cqupt:wxwork:checkin";

  @override
  String get name => "企业微信签到";

  @override
  bool get immediatelyRedirect => true;

  @override
  Future<void> handle(context, data) async {}

  @override
  bool match(data) {
    if (data is! String) return false;
    try {
      final uri = Uri.parse(data);
      final params = uri.queryParameters;
      return uri.host.contains("open.weixin.qq.com") &&
          params["appid"] == "ww3a06d66cb63d5f56" &&
          (Uri.decodeComponent(params["redirect_uri"] ?? '').contains(
            "ehall.cqupt.edu.cn/publicapp/sys/cquptsmqd/tysmqd_sign_in.do",
          ));
    } catch (e) {
      return false;
    }
  }
}

final handlerCquptTronCheckin = CquptTronCheckinCodeHandler();
