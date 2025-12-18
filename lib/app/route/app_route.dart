import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/app/views/pages/index/home.dart';
import 'package:punklorde/app/views/pages/index/notify.dart';
import 'package:punklorde/app/views/pages/index/profile.dart';
import 'package:punklorde/app/views/pages/index/schedule.dart';
import 'package:punklorde/app/views/pages/scanner.dart';
import 'package:punklorde/common/utils/etc/style.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/index.dart';
import 'package:signals/signals_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

final moduleTitleSignal = signal<String>("");
final navIndexSignal = signal<int>(0);

final appRoute = GoRouter(
  initialLocation: '/index/home',
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (context, state) => '/index/home'),
    ShellRoute(
      builder: (context, state, child) {
        resetSystemChromeStyle();
        return Scaffold(
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: StylishBottomBar(
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
                icon: Icon(LucideIcons.house),
                title: const Text("首页"),
              ),
              BottomBarItem(
                icon: Icon(LucideIcons.calendarDays),
                title: const Text("日程"),
              ),
              BottomBarItem(
                icon: Icon(LucideIcons.bell),
                title: const Text("通知"),
              ),
              BottomBarItem(
                icon: Icon(LucideIcons.userRound),
                title: const Text("我"),
              ),
            ],
          ),
          body: SafeArea(child: child),
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
          path: '/p/scanner',
          pageBuilder: (context, state) {
            return NoTransitionPage(child: ScannerView());
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
          path: '/mod/tongtian',
          pageBuilder: (context, state) {
            return NoTransitionPage(child: ModuleTontianView());
          },
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(moduleTitleSignal.watch(context)),
            leading: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: Icon(LucideIcons.x),
            ),
          ),
          body: child,
        );
      },
      routes: [
        GoRoute(
          path: '/plat/wxwork/login/:id',
          pageBuilder: (context, state) {
            moduleTitleSignal.value = '企业微信登录';
            final id = state.pathParameters["id"];
            final appId = state.uri.queryParameters['appid'];
            final agentId = state.uri.queryParameters['agentid'];
            final redirect = state.uri.queryParameters['redirect'];
            if (id == null ||
                appId == null ||
                agentId == null ||
                redirect == null) {
              return NoTransitionPage(child: Text('参数错误'));
            }
            return NoTransitionPage(child: Container());
          },
        ),
      ],
    ),
  ],
);
