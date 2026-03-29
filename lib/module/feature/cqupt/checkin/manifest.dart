import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/module/model/feature.dart';

final featCquptCheckin = Feature(
  id: 'cqupt_checkin',
  name: '签到',
  desc: '',
  icon: const Icon(LucideIcons.clipboardCheck, color: Colors.white, size: 30),
  bgColor: const Color(0xff1177b0),
  version: '1',
  action: (BuildContext context) {
    context.push('/feat/cqupt/checkin');
  },
);
