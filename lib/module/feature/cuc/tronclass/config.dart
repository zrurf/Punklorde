import 'package:flutter/material.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/tronclass/config.dart';
import 'package:punklorde/module/feature/tronclass/service.dart';
import 'package:punklorde/module/platform/cuc/tronclass.dart';

/// 中传畅课配置
final TronclassConfig cucTronclassConfig = TronclassConfig(
  featureId: 'cuc_tron',
  platformId: platCucTronclass.id,
  name: '畅课',
  apiScheme: 'https',
  apiDomain: 'courses.cuc.edu.cn',
  mobileScheme: 'https',
  mobileDomain: 'mobile.courses.cuc.edu.cn',
  iconAsset: 'assets/images/app/tronclass.png',
  bgColor: const Color(0xff1177b0),
  route: '/feat/cuc/tronclass',
  platform: platCucTronclass,
  // 雷达一键签到固定辅助点
  radarAuxiliaryA: const Coordinate(lat: 39.9192, lng: 116.5685),
  radarAuxiliaryB: const Coordinate(lat: 39.9060, lng: 116.5510),
);

/// 中传畅课签到服务
final serviceCucTronclassCheckin = TronclassCheckinService(cucTronclassConfig);
