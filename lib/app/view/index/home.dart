import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/feature.dart';

const double searchBarHeight = 80.0;
const double functionGridHeight = 300.0;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(
      length: currentSchoolSignal.value?.tabs.length ?? 0,
      vsync: this,
    );
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        if (currentSchoolSignal.value == null) {
          context.go('/p/select_school');
        }
      }
    });
  }

  void _onScroll() {
    // 根据滚动偏移判断折叠状态
    final offset = _scrollController.offset;
    final collapsed = offset > 120; // 折叠阈值
    if (_isCollapsed != collapsed) {
      setState(() {
        _isCollapsed = collapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            expandedHeight: 220,
            pinned: true,
            floating: true,
            snap: false,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/banner/default.jpg"),
                    fit: .cover,
                    alignment: .center,
                    colorFilter: .mode(Color(0xb01a1a2e), .srcOver),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    spacing: 26,
                    children: [
                      Padding(
                        padding: const .symmetric(horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            FTappable(
                              onPress: () {
                                context.push('/p/select_school');
                              },
                              style: .delta(),
                              child: Row(
                                children: [
                                  Text(
                                    currentSchoolSignal.value?.name ??
                                        t.app_name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: .left,
                                  ),
                                  const Icon(
                                    LucideIcons.chevronDown,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            FTappable.static(
                              child: Container(
                                padding: const .symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  spacing: 4,
                                  children: [
                                    const Icon(
                                      LucideIcons.scanQrCode,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    Text(
                                      t.common.scan_qrcode,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onPress: () {
                                context.push('/p/universal_scan');
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const .symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              currentSchoolSignal.value?.defaultPinnedFeats.map(
                                (v) {
                                  final feat =
                                      currentSchoolSignal.value?.features[v];
                                  if (feat == null) return Container();
                                  return _buildPinnedFeat(feat);
                                },
                              ).toList() ??
                              [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const .fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: .circular(8),
                    topRight: .circular(8),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: colors.primary,
                  labelColor: colors.foreground,
                  dividerColor: colors.border,
                  unselectedLabelColor: colors.mutedForeground,
                  tabs:
                      currentSchoolSignal.value?.tabs
                          .map((e) => Tab(text: e.name))
                          .toList() ??
                      [],
                ),
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children:
            currentSchoolSignal.value?.tabs
                .map((tab) => tab.widget(context))
                .toList() ??
            [],
      ),
    );
  }

  Widget _buildPinnedFeat(Feature feat) {
    return FTappable(
      onPress: () => feat.action(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FTappable(
            child: Container(
              width: 48,
              height: 48,
              padding: .all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: feat.icon,
            ),
          ),

          const SizedBox(height: 4),
          Text(
            feat.name,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
