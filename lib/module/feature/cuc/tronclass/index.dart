import 'package:flutter/material.dart';
import 'package:punklorde/module/feature/tronclass/view/tronclass_webview_page.dart';
import 'package:punklorde/module/feature/cuc/tronclass/config.dart';

/// 中传畅课页面（基于共享畅课 WebView）
class FeatCucTronclassView extends StatelessWidget {
  const FeatCucTronclassView({super.key});

  @override
  Widget build(BuildContext context) {
    return TronclassWebviewPage(config: cucTronclassConfig);
  }
}