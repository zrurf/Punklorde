import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/app/view/index/home.dart';
import 'package:punklorde/app/view/index/launcher.dart';
import 'package:punklorde/app/view/index/notify.dart';
import 'package:punklorde/app/view/index/profile.dart';
import 'package:punklorde/app/view/index/schedule.dart';
import 'package:punklorde/app/view/page/account.dart';
import 'package:punklorde/app/view/page/checkin_user_page.dart';
import 'package:punklorde/app/view/page/guest.dart';
import 'package:punklorde/app/view/page/scanner.dart';
import 'package:punklorde/app/view/page/select_school.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/checkin/index.dart';
import 'package:punklorde/module/feature/cqupt/sport/index.dart';
import 'package:punklorde/module/feature/cqupt/sport/view/pages/record.dart';
import 'package:punklorde/utils/etc/style.dart';
import 'package:signals/signals_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

final moduleTitleSignal = signal<String>("");
final navIndexSignal = signal<int>(0);

final appRoute = GoRouter(
  initialLocation: '/index/launcher',
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (context, state) => '/index/launcher'),
    ShellRoute(
      builder: (context, state, child) {
        final colors = context.theme.colors;
        resetSystemChromeStyle();
        return Scaffold(
          resizeToAvoidBottomInset: true,
          extendBodyBehindAppBar: true,
          extendBody: true,
          bottomNavigationBar: StylishBottomBar(
            backgroundColor: colors.background,
            currentIndex: navIndexSignal.value,
            option: DotBarOptions(dotStyle: .tile),
            onTap: (value) {
              navIndexSignal.value = value;
              switch (value) {
                case 0:
                  context.go('/index/home');
                  break;
                case 1:
                  context.go('/index/schedule');
                  break;
                case 2:
                  context.go('/index/notify');
                  break;
                case 3:
                  context.go('/index/profile');
                  break;
              }
            },
            items: [
              BottomBarItem(
                icon: const Icon(LucideIcons.house),
                title: Text(t.page.home),
              ),
              BottomBarItem(
                icon: const Icon(LucideIcons.calendarDays),
                title: Text(t.page.schedule),
              ),
              BottomBarItem(
                icon: const Icon(LucideIcons.bell),
                title: Text(t.page.notification),
              ),
              BottomBarItem(
                icon: const Icon(LucideIcons.userRound),
                title: Text(t.page.profile),
              ),
            ],
          ),
          body: child,
        );
      },
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return navigationShell;
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/index/home',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: HomeView()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/index/schedule',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: ScheduleView()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/index/notify',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: NotifyView()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/index/profile',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: ProfileView()),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          extendBodyBehindAppBar: true,
          extendBody: true,
          resizeToAvoidBottomInset: true,
        );
      },
      routes: [
        GoRoute(
          path: '/index/launcher',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LauncherView()),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          extendBodyBehindAppBar: true,
          extendBody: true,
          resizeToAvoidBottomInset: true,
        );
      },
      routes: [
        GoRoute(
          path: "/p/select_school",
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: SelectSchoolPageView());
          },
        ),
        GoRoute(
          path: "/p/scan",
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: ScannerPage());
          },
        ),
        GoRoute(
          path: "/p/universal_scan",
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: UniversalScannerPage());
          },
        ),
        GoRoute(
          path: "/p/checkin_user",
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: CheckinUserPage());
          },
        ),
        GoRoute(
          path: "/s/account/primary",
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: PrimaryAccountPageView());
          },
        ),
        GoRoute(
          path: "/s/account/guest",
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: GuestAccountPageView());
          },
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(body: child);
      },
      routes: [
        GoRoute(
          path: '/feat/cqupt/checkin',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: FeatCquptCheckinView());
          },
        ),
        GoRoute(
          path: '/feat/cqupt/sport',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: FeatCquptSportView());
          },
        ),
        GoRoute(
          path: '/feat/cqupt/sport/record',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: FeatSportCquptRecordView());
          },
        ),
      ],
    ),
  ],
);

void initAppRoute() {
  // 监听路由变化，同步底部栏索引
  appRoute.routerDelegate.addListener(() {
    final String location =
        appRoute.routerDelegate.currentConfiguration.fullPath;

    if (location.startsWith('/index/home')) {
      navIndexSignal.value = 0;
    } else if (location.startsWith('/index/schedule')) {
      navIndexSignal.value = 1;
    } else if (location.startsWith('/index/notify')) {
      navIndexSignal.value = 2;
    } else if (location.startsWith('/index/profile')) {
      navIndexSignal.value = 3;
    }
  });
}
