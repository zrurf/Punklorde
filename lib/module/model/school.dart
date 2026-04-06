import 'package:flutter/material.dart';
import 'package:punklorde/module/model/code_handler.dart';
import 'package:punklorde/module/model/data_interface.dart';
import 'package:punklorde/module/model/feature.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:punklorde/module/model/schedule.dart';

class School {
  final String id; // 学校 ID
  final String name; // 学校名称
  final Set<String> alias; // 学校别名
  final String logo; // 学校logo（资产路径）
  final Map<String, Platform> platforms; // 支持的账号平台
  final Map<String, Feature> features; // 支持的功能
  final Map<Feature, DataInterface> dataInterfaces; // 数据接口
  final ScheduleService scheduleServices; // 课表服务
  final Set<CodeHandler> codeHandlers; // 扫码处理器
  final List<SchoolTab> tabs; // 标签

  final List<String> defaultPinnedFeats; // 默认固定功能ID

  const School({
    required this.id,
    required this.name,
    required this.alias,
    required this.logo,
    required this.platforms,
    required this.features,
    required this.dataInterfaces,
    required this.scheduleServices,
    required this.codeHandlers,
    required this.tabs,
    required this.defaultPinnedFeats,
  });

  T? getDataInterface<T extends DataInterface>(Feature feature) {
    final interface = dataInterfaces[feature];
    if (interface is T) return interface;
    return null;
  }
}

// 学校标签页
class SchoolTab {
  final String id; // Tab ID
  final String name; // Tab 名称
  final Widget Function(BuildContext context) widget; // Tab Widget
  const SchoolTab({required this.id, required this.name, required this.widget});
}
