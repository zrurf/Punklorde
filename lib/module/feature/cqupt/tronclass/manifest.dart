import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/module/model/feature.dart';

final featCquptTron = Feature(
  id: 'cqupt_tron',
  name: '学在重邮',
  desc: '',
  icon: Image.asset('assets/images/app/tronclass.png'),
  bgColor: const Color(0xff1177b0),
  version: '1',
  action: (BuildContext context) {
    context.push('/feat/cqupt/tronclass');
  },
);
