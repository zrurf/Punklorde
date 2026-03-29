import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/module/model/feature.dart';

final featVpnSangfor = Feature(
  id: 'vpn_sangfor',
  name: 'SSL VPN',
  desc: '',
  icon: Image.asset('assets/images/app/sangfor_vpn.png'),
  bgColor: const Color(0xff1177b0),
  version: '1',
  action: (BuildContext context) {
    context.push('/feat/vpn/sangfor');
  },
);
