import 'package:flutter/material.dart';
import 'package:punklorde/core/status/app.dart';

/// 判断当前主题是否为深色
bool isDarkMode(BuildContext context) {
  return (themeModeSignal.value == .dark) ||
      ((themeModeSignal.value == .system) &&
          (MediaQuery.of(context).platformBrightness == Brightness.dark));
}
