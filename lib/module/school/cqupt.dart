import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/account/code_handler.dart';
import 'package:punklorde/module/feature/cqupt/checkin/manifest.dart';
import 'package:punklorde/module/feature/cqupt/sport/manifest.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/code_handler.dart';
import 'package:punklorde/module/feature/cqupt/tronclass/manifest.dart';
import 'package:punklorde/module/feature/scanner/code_handler.dart';
import 'package:punklorde/module/feature/vpn/sangfor/manifest.dart';
import 'package:punklorde/module/model/feature.dart';
import 'package:punklorde/module/model/school.dart';
import 'package:punklorde/module/platform/cqupt/sport.dart';
import 'package:punklorde/module/platform/cqupt/sport_portal.dart';
import 'package:punklorde/module/platform/cqupt/tronclass.dart';
import 'package:punklorde/module/tab/common_tabs.dart';
import 'package:punklorde/utils/etc/url.dart';

// 功能列表
final Map<String, Feature> _features = {
  featCquptCheckin.id: featCquptCheckin, // 签到
  featSportCqupt.id: featSportCqupt, // 重邮智慧体育
  featCquptTron.id: featCquptTron, // 学在重邮
  featVpnSangfor.id: featVpnSangfor, // 深信服SSL VPN
  _featLinkAcademicPortal.id: _featLinkAcademicPortal, // 教务在线链接
  _featLinkAcademicPortalOld.id: _featLinkAcademicPortalOld, // 老版教务在线链接
};

// CQUPT 重庆邮电大学
final School schoolCqupt = School(
  id: 'cqupt',
  name: '重庆邮电大学',
  alias: {"重邮"},
  logo: "assets/images/logo/cqupt.png",
  platforms: {
    platCquptTronclass.id: platCquptTronclass,
    platCquptSport.id: platCquptSport,
    platCquptSportPortal.id: platCquptSportPortal,
  },
  features: _features,
  dataInterfaces: {},
  codeHandlers: {handlerUrlLink, handlerGuestAccount, handlerCquptTronCheckin},
  tabs: [tabSchedule, tabFunctions(_features.values.toList())],
  defaultPinnedFeats: [
    featCquptCheckin.id,
    featSportCqupt.id,
    featCquptTron.id,
    featVpnSangfor.id,
  ],
);

final _featLinkAcademicPortal = Feature(
  id: 'link_ap',
  name: '教务在线',
  desc: '',
  icon: const Icon(LucideIcons.link, color: Colors.white, size: 30),
  bgColor: const Color(0xff41ba49),
  version: '1',
  action: (BuildContext context) {
    launchInBrowser("https://jw.cqupt.edu.cn/");
  },
);

final _featLinkAcademicPortalOld = Feature(
  id: 'link_ap_old',
  name: '老版教务在线',
  desc: '',
  icon: const Icon(LucideIcons.link, color: Colors.white, size: 30),
  bgColor: const Color(0xff41ba49),
  version: '1',
  action: (BuildContext context) {
    launchInBrowser("http://jwzx.cqupt.edu.cn/indexold.php");
  },
);
