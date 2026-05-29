import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/module/model/feature.dart';

final featVpnSangfor = Feature(
  id: 'vpn_sangfor',
  name: 'SSL VPN',
  desc: 'Connect to campus VPN via Sangfor EasyConnect',
  icon: Image.asset('assets/images/app/sangfor_vpn.png', width: 48, height: 48),
  bgColor: const Color(0xff1177b0),
  version: '1',
  action: (BuildContext context) {
    context.push(
      '/feat/vpn/sangfor?server=${Uri.encodeComponent("vpn.cqupt.edu.cn")}',
    );
  },
);
