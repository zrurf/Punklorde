import 'package:flutter/material.dart';
import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/module/feature/tronclass/config.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';

/// 学在重邮（畅课）配置
final TronclassConfig cquptTronclassConfig = TronclassConfig(
  featureId: 'cqupt_tron',
  platformId: platCquptTronclass.id,
  name: '学在重邮',
  apiScheme: 'http',
  apiDomain: 'lms.tc.cqupt.edu.cn',
  mobileScheme: 'http',
  mobileDomain: 'mobile.tc.cqupt.edu.cn',
  iconAsset: 'assets/images/app/tronclass.png',
  bgColor: const Color(0xff1177b0),
  route: '/feat/cqupt/tronclass',
  platform: platCquptTronclass,
  // 雷达一键签到固定辅助点
  radarAuxiliaryA: const Coordinate(lat: 29.5380, lng: 106.6140),
  radarAuxiliaryB: const Coordinate(lat: 29.5195, lng: 106.5964),
);
