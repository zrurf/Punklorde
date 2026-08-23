import 'package:flutter/material.dart';
import 'package:punklorde/module/feature/tronclass/view/tronclass_webview_page.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/config.dart';

/// 学在重邮页面（基于共享畅课 WebView）
class FeatCquptTronclassView extends StatelessWidget {
  const FeatCquptTronclassView({super.key});

  @override
  Widget build(BuildContext context) {
    return TronclassWebviewPage(config: cquptTronclassConfig);
  }
}