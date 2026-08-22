import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/app/route/app_route.dart';
import 'package:punklorde/app/theme/default.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/utils/etc/style.dart';
import 'package:signals/signals_flutter.dart';

class MainMobileApp extends SignalWidget {
  const MainMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = themeModeSignal.value;
    late final ThemeMode themeModeMaterial;
    switch (themeMode) {
      case .light:
        themeModeMaterial = .light;
      case .dark:
        themeModeMaterial = .dark;
      case .system:
        themeModeMaterial = .system;
    }

    initAppRoute();

    return MaterialApp.router(
      title: t.app_name,
      theme: lightTheme.toApproximateMaterialTheme(),
      darkTheme: darkTheme.toApproximateMaterialTheme(),
      themeMode: themeModeMaterial,
      routerConfig: appRoute,
      builder: (context, child) {
        late final FThemeData theme;
        late final bool isDark;
        switch (themeMode) {
          case .light:
            theme = lightTheme;
            isDark = false;
          case .dark:
            theme = darkTheme;
            isDark = true;
          case .system:
            isDark =
                MediaQuery.of(context).platformBrightness == Brightness.dark;
            theme = isDark ? darkTheme : lightTheme;
        }
        // 跟随主题更新状态栏/手势栏样式
        WidgetsBinding.instance.addPostFrameCallback((_) {
          applySystemUiStyle(
            isDark: isDark,
            navigationBarColor: theme.colors.background,
          );
        });
        return FTheme(
          data: theme,
          child: FToaster(
            child: LoaderOverlay(child: child ?? const SizedBox()),
          ),
        );
      },
    );
  }
}
