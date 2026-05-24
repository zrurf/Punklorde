import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TronclassContentBlocker {
  static final envGuardBlocker = ContentBlocker(
    trigger: ContentBlockerTrigger(
      urlFilter: ".*anti-tamper-guard.*",
      resourceType: [.SCRIPT, .RAW, .DOCUMENT],
    ),
    action: ContentBlockerAction(type: .BLOCK),
  );
}
