import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/api/client.dart';
import 'package:punklorde/module/feature/chaoxing/core/js_handler.dart';
import 'package:punklorde/module/feature/chaoxing/model/auth.dart';
import 'package:punklorde/module/feature/chaoxing/model/common.dart';
import 'package:punklorde/module/feature/chaoxing/view/widgets/chaoxing_webview.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:signals/signals_flutter.dart';
import 'package:punklorde/module/feature/chaoxing/view/widgets/simple_app_bar.dart';
import 'package:punklorde/module/feature/chaoxing/view/pages/course_active_checkin.dart';

class CourseActivePage extends StatefulWidget {
  final int classId;
  final int courseId;
  final int personId;
  final String className;
  final String courseName;

  const CourseActivePage({
    super.key,
    required this.classId,
    required this.courseId,
    required this.personId,
    required this.className,
    required this.courseName,
  });

  @override
  State<CourseActivePage> createState() => _CourseActivePageState();
}

class _CourseActivePageState extends State<CourseActivePage> {
  final _tabIndex = signal(0);
  final _actives = signal<List<ActiveResult>>([]);
  final _loading = signal(true);
  final _activeType = <int, ActiveType>{};

  // 共享 WebView（考试 & 作业共用一个）
  final _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  ChaoxingJSHandler? _jsHandler;
  bool _webViewCreated = false;
  int _currentWebViewTab = 0; // 当前 WebView 显示的是哪个 tab (1=考试, 2=作业)

  String get _examUrl =>
      'https://mooc1-api.chaoxing.com/exam-ans/exam/phone/task-list'
      '?courseId=${widget.courseId}&classId=${widget.classId}&cpi=${widget.personId}';

  String get _homeworkUrl =>
      'https://mooc1-api.chaoxing.com/mooc-ans/work/task-list'
      '?courseId=${widget.courseId}&classId=${widget.classId}&cpi=${widget.personId}';

  String get _currentWebViewUrl =>
      _currentWebViewTab == 1 ? _examUrl : _homeworkUrl;

  @override
  void initState() {
    super.initState();
    _loadActiveList();
  }

  Future<void> _loadActiveList() async {
    _loading.value = true;
    try {
      final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
      if (cred != null) {
        final cache = await AuthCredentialCache.fromCredential(cred);
        final api = ApiClient();
        final result = await api.getActives(
          cache,
          widget.courseId.toString(),
          widget.classId.toString(),
        );
        if (result != null) {
          for (final r in result) {
            _activeType[r.id] = r.getActiveType;
          }
          _actives.value = result;
        }
      }
    } catch (_) {
      // ignore
    } finally {
      _loading.value = false;
    }
  }

  /// 系统回退：WebView tab 时先回退页面历史，否则退出
  Future<bool> _handleBack() async {
    final tab = _tabIndex.value;
    // 活动 tab，允许退出
    if (tab == 0) return true;
    // WebView tab：优先 WebView 内回退
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    }
    // WebView 已到根，允许退出
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabIndex.watch(context);

    // 切到 WebView tab 时标记已打开
    if (tab == 1 || tab == 2) {
      if (!_webViewCreated) _webViewCreated = true;
      // 切换 WebView tab 时更新 URL
      if (_webViewController != null && _currentWebViewTab != tab) {
        _currentWebViewTab = tab;
        _webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(_currentWebViewUrl)),
        );
      }
    }

    // 0 = 活动, 1 = 共享 WebView (考试/作业)
    final displayIndex = tab == 0 ? 0 : 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final canExit = await _handleBack();
          if (canExit && mounted) context.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SimpleAppBar.nested(
                title: widget.className,
                subtitle: widget.courseName,
              ),
              _buildTabBar(context, tab),
              Expanded(
                child: IndexedStack(
                  index: displayIndex,
                  children: [
                    _buildActivesView(),
                    _webViewCreated
                        ? _buildSharedWebView()
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, int tab) {
    final colors = context.theme.colors;
    final labels = [
      t.submodule.chaoxing.course_activities, // 活动
      t.submodule.chaoxing.exam, // 考试
      t.submodule.chaoxing.homework, // 作业
    ];

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == tab;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tabIndex.value = i,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 4,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected
                          ? colors.foreground
                          : colors.mutedForeground,
                    ),
                  ),
                  if (selected)
                    Container(height: 2, width: 24, color: colors.primary)
                  else
                    const SizedBox(height: 2),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===== 活动 Tab =====

  Widget _buildActivesView() {
    final actives = _actives.watch(context);
    final loading = _loading.watch(context);
    final colors = context.theme.colors;

    if (loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (actives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.clipboardList,
              size: 40,
              color: colors.mutedForeground.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              t.submodule.chaoxing.no_activities,
              style: TextStyle(fontSize: 15, color: colors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: actives.length,
        itemBuilder: (context, index) =>
            _buildActiveCard(context, actives[index]),
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, ActiveResult data) {
    final colors = context.theme.colors;
    final type = _activeType[data.id] ?? ActiveType.unknown;
    final typeLabel = _typeLabel(type, colors);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final activeType = _activeType[data.id] ?? ActiveType.unknown;
          switch (activeType) {
            case ActiveType.signIn:
            case ActiveType.scheduledSignIn:
              handleSignIn(context, data);
            case ActiveType.notification:
              handleNotification(context, data);
            case ActiveType.signOut:
            case ActiveType.unknown:
              break; // 暂不处理
          }
        },
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (typeLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeLabel.$2.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          typeLabel.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: typeLabel.$2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (data.description != null &&
                    data.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.startTime != null
                          ? formatDate(data.startTime!)
                          : '--',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (data.status != null) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: data.status == 1
                              ? Colors.green
                              : colors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.status == 1 ? t.label.ongoing : t.label.ended,
                        style: TextStyle(
                          fontSize: 12,
                          color: data.status == 1
                              ? Colors.green
                              : colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color)? _typeLabel(ActiveType type, FColors colors) {
    switch (type) {
      case ActiveType.signIn:
        return ('签到', Colors.blue);
      case ActiveType.signOut:
        return ('签退', Colors.orange);
      case ActiveType.scheduledSignIn:
        return ('定时签到', Colors.purple);
      case ActiveType.notification:
        return ('通知', Colors.green);
      case ActiveType.unknown:
        return null;
    }
  }

  // ===== 共享 WebView（考试 / 作业） =====

  Widget _buildSharedWebView() {
    final cred = authManager.getPrimaryAuthByPlatform(platChaoxing.id);
    if (cred == null) {
      return const Center(child: Text('请先登录学习通'));
    }

    // 首次创建时使用当前 tab 的 URL
    final initUrl = _currentWebViewTab == 0
        ? _examUrl // 默认考试（首次创建时 tab 必然为 1 或 2）
        : _currentWebViewUrl;

    return ChaoxingWebView(
      key: _webViewKey,
      config: ChaoxingWebViewConfig(
        url: initUrl,
        credential: cred,
        userAgent: cred.ext?["ua"],
        onPageStarted: (controller, url) {
          _webViewController = controller;
          _jsHandler = ChaoxingJSHandler(
            controller,
            onOpenUrl: (newUrl) async {
              // 打开独立 WebView 页面，而非在当前 WebView 内导航
              if (mounted) {
                context.push('/feat/chaoxing/webview', extra: newUrl);
              }
            },
          );
        },
        onJSBridgeNotification: (name, payload) {
          _jsHandler?.handle(name, payload);
        },
      ),
    );
  }
}
