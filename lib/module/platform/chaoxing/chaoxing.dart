import 'package:flutter/material.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';

class ChaoxingPlatform extends Platform {
  @override
  String get id => "chaoxing";

  @override
  String get name => "超星学习通";

  @override
  String get descript => "用于学习通";

  @override
  Future<AuthCredential?> login(BuildContext context) async {
    return null;
  }

  @override
  Future<void> logout(AuthCredential credential) async {
    return;
  }

  @override
  Future<AuthCredential?> refresh(AuthCredential oldCredential) async {
    return null;
  }

  @override
  Future<bool> validate(AuthCredential credential) async {
    return false;
  }
}
