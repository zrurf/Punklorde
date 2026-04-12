import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/module/model/feature.dart';

final featChaoxing = Feature(
  id: 'chaoxing',
  name: '学习通',
  desc: '',
  icon: Image.asset('assets/images/app/chaoxing.png'),
  bgColor: const Color(0xffe9002d),
  version: '1',
  action: (BuildContext context) {
    context.push('/feat/chaoxing');
  },
);
