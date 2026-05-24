import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/data.dart';
import 'package:punklorde/module/feature/chaoxing/view/pages/course_page.dart';
import 'package:punklorde/module/feature/chaoxing/view/pages/homework_page.dart';
import 'package:punklorde/module/feature/chaoxing/view/pages/messages_page.dart';
import 'package:punklorde/module/feature/chaoxing/view/pages/profile_page.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:signals/signals_flutter.dart';

void initChaoxingServices() {
  initStatus();
}

class FeatChaonxingView extends StatefulWidget {
  const FeatChaonxingView({super.key});

  @override
  State<FeatChaonxingView> createState() => _FeatChaonxingViewState();
}

class _FeatChaonxingViewState extends State<FeatChaonxingView> {
  final Signal<int> _tabIndex = signal(0);
  final _homeworkKey = GlobalKey<HomeworkPageState>();

  /// 作业 WebView 是否在首页（控制底部导航栏显隐）
  final _isAtHomeworkHome = signal(true);

  // IndexedStack 保证切换页面时 WebView 等组件不重建
  late final _pages = <Widget>[
    const CoursePage(),
    HomeworkPage(
      key: _homeworkKey,
      onPageChanged: (isAtHome) => _isAtHomeworkHome.value = isAtHome,
    ),
    const MessagesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final index = _tabIndex.watch(context);
    final tab = t.submodule.chaoxing;
    // 仅当不在作业 Tab 或作业 WebView 在首页时显示底部导航栏
    final showBottomNav = index != 1 || _isAtHomeworkHome.watch(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPressed(context, index);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              // 紧凑顶部栏
              _buildHeader(context, colors, index),
              // 内容区域 — IndexedStack 保活
              Expanded(
                child: IndexedStack(index: index, children: _pages),
              ),
              // 仅主页/作业首页显示底部导航
              if (showBottomNav) _buildBottomNav(index, tab, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FColors colors, int index) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // 返回按钮 — WebView 时先回退页面历史，否则退出模块
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBackPressed(context, index),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xffe9002d),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/images/app/chaoxing.png'),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            platChaoxing.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // 扫码按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/p/universal_scan'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.scanLine,
                size: 18,
                color: colors.mutedForeground,
              ),
            ),
          ),
          // 设置按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.bolt,
                size: 18,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBackPressed(BuildContext context, int index) async {
    if (index == 1) {
      // 作业 Tab — 尝试 WebView 回退
      final state = _homeworkKey.currentState;
      if (state != null) {
        final wentBack = await state.goBack();
        if (wentBack) return; // WebView 回退成功，不退出
      }
    }
    // 否则退出模块
    if (context.mounted) {
      context.pop();
    }
  }

  Widget _buildBottomNav(int currentIndex, var tab, FColors colors) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _NavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: LucideIcons.bookOpen,
            label: tab.courses,
            onTap: () => _tabIndex.value = 0,
          ),
          _NavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: LucideIcons.fileText,
            label: tab.homework,
            onTap: () => _tabIndex.value = 1,
          ),
          _NavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: LucideIcons.messageCircle,
            label: tab.messages,
            onTap: () => _tabIndex.value = 2,
          ),
          _NavItem(
            index: 3,
            currentIndex: currentIndex,
            icon: LucideIcons.userRound,
            label: tab.profile,
            onTap: () => _tabIndex.value = 3,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final selected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Container(
                  width: 28,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(height: 5),
              Icon(
                icon,
                size: selected ? 20 : 19,
                color: selected ? colors.primary : colors.mutedForeground,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? colors.primary : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
