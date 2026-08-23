import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:punklorde/app/route/app_route.dart';
import 'package:punklorde/app/theme/default.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/utils/etc/style.dart';
import 'package:signals/signals_flutter.dart';

/// 应用根部：同时监听当前语言与学校变化，
/// 变化时通过重新生成 key 强制整树重建，确保首页/设置等长驻页面立即刷新
class MainMobileApp extends StatelessWidget {
  const MainMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _AppKeyScope(child: const _AppView());
  }
}

/// 语言选择与学校双 Signal 监听，驱动 key 重建
class _AppKeyScope extends StatelessWidget {
  final Widget child;

  const _AppKeyScope({required this.child});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        // 订阅语言选择信号，切换语言时触发重建
        localeSignal.value;
        final localeKey = localeRawCode(LocaleSettings.instance.currentLocale);
        final schoolKey = currentSchoolSignal.value?.id ?? '';
        return KeyedSubtree(
          key: ValueKey('${localeKey}_$schoolKey'),
          child: child,
        );
      },
    );
  }
}

class _AppView extends SignalWidget {
  const _AppView();

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
