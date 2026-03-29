import 'package:flutter/services.dart';

// 复制内容到剪贴板
Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}
