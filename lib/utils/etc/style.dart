import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Brightness? _lastAppliedIconBrightness;

/// 根据主题亮度应用系统栏样式（状态栏 / 手势导航栏），并跟随主题变化。
///
/// - [isDark]：当前是否为深色主题。
/// - [navigationBarColor]：导航栏/手势栏区域背景色，与主题背景保持一致，
///   避免部分机型（如 MIUI）在透明导航栏下渲染为黑色。
void applySystemUiStyle({
  required bool isDark,
  Color? navigationBarColor,
}) {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final iconBrightness = isDark ? Brightness.light : Brightness.dark;
  if (_lastAppliedIconBrightness == iconBrightness) return;

  _lastAppliedIconBrightness = iconBrightness;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: iconBrightness,
      systemNavigationBarColor: navigationBarColor ?? Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
    ),
  );
}