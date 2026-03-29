import 'package:punklorde/module/model/code_handler.dart';
import 'package:punklorde/utils/etc/url.dart';

/// 链接跳转
class UrlLinkCodeHandler extends CodeHandler {
  @override
  String get id => "common:url_link";

  @override
  String get name => "跳转链接";

  @override
  bool get immediatelyRedirect => false;

  @override
  Future<void> handle(context, data) async {
    launchInBrowser(data as String);
  }

  @override
  bool match(data) {
    return data is String && isUrl(data);
  }

  bool isUrl(String str) {
    return str.startsWith("http://") || str.startsWith("https://");
  }
}

final handlerUrlLink = UrlLinkCodeHandler();
