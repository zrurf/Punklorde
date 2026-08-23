import 'package:flutter/material.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/model/platform.dart';

/// 畅课平台配置
///
/// 畅课（Tronclass）各校共用同一套 API 路径，仅登录入口（桌面端）与
/// 移动端域名不同。抽象 feature 通过该配置实例化为具体学校功能。
class TronclassConfig {
  final String featureId; // 功能ID
  final String platformId; // 平台ID
  final String name; // 平台名称
  final String apiScheme; // 桌面端（API）协议
  final String apiDomain; // 桌面端（API）域名
  final String mobileScheme; // 移动端协议
  final String mobileDomain; // 移动端域名
  final String iconAsset; // 功能图标
  final Color bgColor; // 功能背景色
  final String route; // 功能路由
  final Platform platform; // 登录平台实例

  /// 雷达一键签到固定辅助点（使用时基于当前位置生成）
  final Coordinate? radarAuxiliaryA;
  final Coordinate? radarAuxiliaryB;
  final int pinLength; // 数字签到码长度

  const TronclassConfig({
    required this.featureId,
    required this.platformId,
    required this.name,
    required this.apiScheme,
    required this.apiDomain,
    required this.mobileScheme,
    required this.mobileDomain,
    required this.iconAsset,
    required this.bgColor,
    required this.route,
    required this.platform,
    this.radarAuxiliaryA,
    this.radarAuxiliaryB,
    this.pinLength = 4,
  });

  /// 桌面端（API）基地址
  String get apiBaseUrl => '$apiScheme://$apiDomain';

  /// 移动端基地址
  String get mobileBaseUrl => '$mobileScheme://$mobileDomain';
}
