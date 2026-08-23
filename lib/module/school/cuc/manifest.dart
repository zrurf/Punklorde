import 'package:punklorde/core/account/code_handler.dart';
import 'package:punklorde/module/feature/cuc/tronclass/code_handler.dart';
import 'package:punklorde/module/feature/cuc/tronclass/manifest.dart';
import 'package:punklorde/module/feature/cuc/checkin/manifest.dart';
import 'package:punklorde/module/feature/scanner/code_handler.dart';
import 'package:punklorde/module/model/feature.dart';
import 'package:punklorde/module/model/schedule.dart';
import 'package:punklorde/module/model/school.dart';
import 'package:punklorde/module/platform/cuc/tronclass.dart';
import 'package:punklorde/module/tab/common_tabs.dart';

// 功能列表
final Map<String, Feature> _features = {
  featCucCheckin.id: featCucCheckin, // 签到
  featCucTron.id: featCucTron, // 畅课
};

// CUC 中国传媒大学
final School schoolCuc = School(
  id: 'cuc',
  name: '中国传媒大学',
  alias: {"中传"},
  logo: "assets/images/logo/cuc.png",
  platforms: {platCucTronclass.id: platCucTronclass},
  features: _features,
  dataInterfaces: {},
  scheduleServices: NoopScheduleService(),
  codeHandlers: {
    handlerUrlLink,
    handlerGuestAccount,
    handlerCucTronclassCheckin,
  },
  tabs: [tabFunctions(_features.values.toList())],
  defaultPinnedFeats: [featCucCheckin.id, featCucTron.id],
);
