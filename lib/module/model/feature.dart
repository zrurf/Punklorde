import 'package:flutter/material.dart';

class Feature {
  final String id; // 功能 ID
  final String name; // 功能名称
  final String desc; // 功能描述
  final Widget icon; // 功能图标
  final Color bgColor; // 功能背景颜色
  final String version; // 功能版本
  final void Function(BuildContext context) action; // 功能事件

  Feature({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.bgColor,
    required this.version,
    required this.action,
  });
}
