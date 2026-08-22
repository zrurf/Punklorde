import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/utils/etc/fdialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/resource/model.dart';
import 'package:punklorde/core/status/resource.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

class DlCachePage extends StatefulWidget {
  const DlCachePage({super.key});

  @override
  State<DlCachePage> createState() => _DlCachePageState();
}

class _DlCachePageState extends State<DlCachePage> {
  late final Signal<List<CacheEntry>> _entriesSignal;
  late final Signal<int> _totalSizeSignal;
  late final Signal<bool> _loadingSignal;
  late final Signal<Set<String>> _refreshingKeys;

  final Map<String, ReadonlySignal<bool>> _isRefreshingMap = {};

  @override
  void initState() {
    super.initState();
    _entriesSignal = signal<List<CacheEntry>>([]);
    _totalSizeSignal = signal<int>(0);
    _loadingSignal = signal<bool>(true);
    _refreshingKeys = signal<Set<String>>({});
    _refreshCacheList();
  }

  ReadonlySignal<bool> _getIsRefreshing(String key) {
    return _isRefreshingMap.putIfAbsent(
      key,
      () => computed(() => _refreshingKeys.value.contains(key)),
    );
  }

  Future<void> _refreshCacheList() async {
    _loadingSignal.value = true;
    try {
      final entries = await resourceManager.listCacheEntries();
      final totalSize = await resourceManager.getTotalCacheSize();
      _entriesSignal.value = entries;
      _totalSizeSignal.value = totalSize;
    } finally {
      _loadingSignal.value = false;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return DateFormat('HH:mm').format(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  // ══════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- 头部（仅当 entries 列表为空/非空变化时重建） ---
            SignalBuilder(
              builder: (context) => FHeader.nested(
                title: Text(t.setting.dl_cache),
                prefixes: [FHeaderAction.back(onPress: () => context.pop())],
                suffixes: _entriesSignal.value.isEmpty
                    ? []
                    : [
                        FHeaderAction(
                          icon: const Icon(LucideIcons.refreshCw, size: 20),
                          onPress: _doRefreshAll,
                        ),
                        FHeaderAction(
                          icon: Icon(
                            LucideIcons.trash2,
                            color: colors.destructive,
                            size: 20,
                          ),
                          onPress: _confirmClearAll,
                        ),
                      ],
              ),
            ),
            // --- 摘要栏（仅当总量 / 数量 / loading 变化时重建） ---
            SignalBuilder(
              builder: (context) {
                if (_loadingSignal.value || _entriesSignal.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.hardDrive,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${t.setting.cache_total}: ${_formatSize(_totalSizeSignal.value)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        LucideIcons.file,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${t.setting.cache_count}: ${_entriesSignal.value.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // --- 内容区（仅当 loading / 空状态 / 列表项数量变化时重建） ---
            Expanded(
              child: SignalBuilder(
                builder: (context) {
                  final loading = _loadingSignal.value;
                  final entries = _entriesSignal.value;

                  if (loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (entries.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const FDivider(),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _CacheTile(
                          entry: entry,
                          isRefreshing: _getIsRefreshing(entry.key),
                          onRefresh: () => _doRefreshSingle(entry.key),
                          onDelete: () => _confirmDeleteCache(entry.key),
                          onTap: () => _showDetailDialog(entry),
                          formatSize: _formatSize,
                          formatDate: _formatDate,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Icon(LucideIcons.folderOpen, color: colors.primary, size: 24),
          Text(
            t.setting.cache_no_cache,
            style: TextStyle(color: colors.mutedForeground, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── 详情弹窗 ──────────────────────────────────────────────

  void _showDetailDialog(CacheEntry entry) {
    final t = Translations.of(context);
    showFDialog(
      context: context,
      builder: (context, style, animation) => punklordeDialog(
        style: style,
        animation: animation,
        title: Text(t.setting.cache_detail),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            _detailRow(t.setting.cache_detail_key, entry.key),
            _detailRow(t.setting.cache_detail_path, entry.filePath),
            _detailRow(t.setting.cache_total, _formatSize(entry.size)),
            _detailRow(
              t.title.last_update,
              DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.lastModified),
            ),
            _detailRow(
              t.setting.cache_last_accessed,
              entry.lastAccessed != null
                  ? DateFormat(
                      'yyyy-MM-dd HH:mm:ss',
                    ).format(entry.lastAccessed!)
                  : t.setting.cache_never_accessed,
            ),
          ],
        ),
        actions: [
          FButton(
            variant: .primary,
            size: .xs,
            onPress: () => Navigator.of(context).pop(),
            child: Text(t.notice.confirm),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colors = context.theme.colors;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 12),
          textAlign: .start,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  刷新逻辑
  // ══════════════════════════════════════════════════════════

  Future<void> _doRefreshSingle(String key) async {
    _refreshingKeys.value = {..._refreshingKeys.value, key};
    try {
      await resourceManager.checkForUpdate(key);
      await _refreshCacheList();
      if (mounted) {
        _showToast(
          context: context,
          variant: .primary,
          icon: LucideIcons.circleCheck,
          title: t.setting.cache_refreshed,
        );
      }
    } catch (e) {
      await _refreshCacheList();
      if (mounted) {
        _showToast(
          context: context,
          variant: .destructive,
          icon: LucideIcons.circleX,
          title: t.common.failed,
          description: e.toString(),
        );
      }
    } finally {
      _refreshingKeys.value = _refreshingKeys.value
          .where((k) => k != key)
          .toSet();
    }
  }

  void _doRefreshAll() {
    final keys = _entriesSignal.value.map((e) => e.key).toList();
    if (keys.isEmpty) return;

    _refreshingKeys.value = keys.toSet();

    unawaited(_runRefreshAll(keys));
  }

  Future<void> _runRefreshAll(List<String> keys) async {
    var success = 0;
    var failed = 0;

    await Future.wait(
      keys.map((key) async {
        try {
          await resourceManager.checkForUpdate(key);
          success++;
        } catch (_) {
          failed++;
        }
      }),
    );

    await _refreshCacheList();
    _refreshingKeys.value = {};

    if (!mounted) return;

    final t = Translations.of(context);
    if (failed == 0) {
      _showToast(
        context: context,
        variant: .primary,
        icon: LucideIcons.circleCheck,
        title: t.setting.cache_cleared(count: success),
      );
    } else {
      _showToast(
        context: context,
        variant: .primary,
        icon: LucideIcons.circleCheck,
        title: '${t.setting.cache_refreshed} ($success/${keys.length})',
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  //  删除逻辑
  // ══════════════════════════════════════════════════════════

  void _confirmDeleteCache(String key) {
    showFDialog(
      context: context,
      builder: (context, style, animation) => punklordeDialog(
        style: style,
        animation: animation,
        title: Text(t.action.delete),
        body: Text(t.setting.cache_delete_confirm),
        actions: [
          FButton(
            variant: .secondary,
            size: .xs,
            onPress: () => Navigator.of(context).pop(),
            child: Text(t.notice.cancel),
          ),
          FButton(
            variant: .destructive,
            size: .xs,
            onPress: () {
              Navigator.of(context).pop();
              _doDeleteCache(key);
            },
            child: Text(t.action.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _doDeleteCache(String key) async {
    await resourceManager.deleteCache(key);
    await _refreshCacheList();
    if (!mounted) return;
    _showToast(
      context: context,
      variant: .destructive,
      icon: LucideIcons.circleCheck,
      title: t.setting.cache_deleted,
    );
  }

  void _confirmClearAll() {
    showFDialog(
      context: context,
      builder: (context, style, animation) => punklordeDialog(
        style: style,
        animation: animation,
        title: Text(t.setting.cache_clear_all),
        body: Text(t.setting.cache_clear_all_confirm),
        actions: [
          FButton(
            variant: .secondary,
            size: .xs,
            onPress: () => Navigator.of(context).pop(),
            child: Text(t.notice.cancel),
          ),
          FButton(
            variant: .destructive,
            size: .xs,
            onPress: () {
              Navigator.of(context).pop();
              _doClearAll();
            },
            child: Text(t.setting.cache_clear_all),
          ),
        ],
      ),
    );
  }

  Future<void> _doClearAll() async {
    final count = await resourceManager.clearAllCache();
    await _refreshCacheList();
    if (!mounted) return;
    _showToast(
      context: context,
      variant: .destructive,
      icon: LucideIcons.circleCheck,
      title: t.setting.cache_cleared(count: count),
    );
  }

  // ─── Toast 辅助 ────────────────────────────────────────────

  void _showToast({
    required BuildContext context,
    required FToastVariant variant,
    required IconData icon,
    required String title,
    String? description,
  }) {
    showFToast(
      context: context,
      variant: variant,
      alignment: .topCenter,
      title: Text(title),
      description: description != null ? Text(description) : null,
      duration: const Duration(seconds: 2),
      icon: Icon(icon),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  独立的缓存项组件（仅 watch 自己的刷新状态）
// ═══════════════════════════════════════════════════════════

class _CacheTile extends StatelessWidget {
  const _CacheTile({
    required this.entry,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onDelete,
    required this.onTap,
    required this.formatSize,
    required this.formatDate,
  });

  final CacheEntry entry;
  final ReadonlySignal<bool> isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final String Function(int) formatSize;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final colors = context.theme.colors;

    return SignalBuilder(
      builder: (context) {
        final refreshing = isRefreshing.value;

        return InkWell(
          onTap: refreshing ? null : onTap,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatSize(entry.size),
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${t.title.last_update}: ${formatDate(entry.lastModified)}',
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (entry.lastAccessed != null)
                      Text(
                        '${t.setting.cache_last_accessed}: ${formatDate(entry.lastAccessed!)}',
                        style: TextStyle(
                          color: colors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (refreshing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      onPressed: onRefresh,
                      tooltip: t.setting.cache_refresh,
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, color: colors.destructive),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      onPressed: onDelete,
                      tooltip: t.action.delete,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
