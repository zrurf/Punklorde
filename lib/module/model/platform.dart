import 'package:flutter/material.dart';
import 'package:punklorde/module/model/auth.dart';

abstract class Platform {
  String get id; // 平台ID
  String get name; // 平台名称
  String get descript; // 描述

  Future<AuthCredential?> login(BuildContext context);
  Future<void> logout(AuthCredential credential);
  Future<AuthCredential?> refresh(AuthCredential oldCredential);
  Future<bool> validate(AuthCredential credential);
}
