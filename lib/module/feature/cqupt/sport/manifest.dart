import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/module/model/feature.dart';

final featSportCqupt = Feature(
  id: 'cqupt_sport',
  name: '重邮智慧体育',
  desc: '',
  icon: Image.asset('assets/icon/icon_sport.png'),
  bgColor: const Color(0xff1177b0),
  version: '1', // 等于小程序版本
  action: (BuildContext context) {
    context.push('/feat/cqupt/sport');
  },
);
