import 'package:flutter/material.dart';

abstract class CodeHandler {
  String get id; // 唯一标识
  String get name; // 名称
  bool get immediatelyRedirect; // 是否立即跳转

  bool match(dynamic data); // 匹配数据
  Future<void> handle(BuildContext context, dynamic data); // 处理数据
}
