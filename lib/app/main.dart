import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/app/route/app_route.dart';
import 'package:punklorde/app/theme/default.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

class MainMobileApp extends StatelessWidget {
  const MainMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = themeModeSignal.watch(context);
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
        switch (themeMode) {
          case .light:
            theme = lightTheme;
          case .dark:
            theme = darkTheme;
          case .system:
            theme =
                MediaQuery.of(context).platformBrightness == Brightness.light
                ? lightTheme
                : darkTheme;
        }
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
