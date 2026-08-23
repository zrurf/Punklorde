import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';

/// 签到结果页面：负责执行签到，加载完成后展示各账号结果
class CheckinResultPage extends StatefulWidget {
  final Platform platform;

  /// 参与签到的全部账号
  final List<AuthCredential> credentials;

  /// 执行签到，按传入顺序返回每个账号的结果
  final Future<List<bool>> Function(List<AuthCredential> credentials) onCheckin;

  const CheckinResultPage({
    super.key,
    required this.platform,
    required this.credentials,
    required this.onCheckin,
  });

  @override
  State<StatefulWidget> createState() => _CheckinResultPageState();
}

class _CheckinResultPageState extends State<CheckinResultPage> {
  /// 待重试账号在 [CheckinResultPage.credentials] 中的下标集合
  Set<int> _retryIndices = {};

  /// 各账号的签到结果，null 表示未完成
  late final List<bool?> _results;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _results = List<bool?>.filled(widget.credentials.length, null);
    _checkin(List.generate(widget.credentials.length, (i) => i));
  }

  bool get isError => _results.isEmpty;
  bool get isAllSuccess => _results.every((e) => e == true);
  bool get isAllFailed =>
      _results.isNotEmpty && _results.every((e) => e == false);
  int get successCount => _results.where((e) => e == true).length;

  /// 签到指定下标的账号并回写结果
  Future<void> _checkin(List<int> indices) async {
    final credentials = [for (final i in indices) widget.credentials[i]];
    setState(() => _running = true);
    List<bool> result;
    try {
      result = await widget.onCheckin(credentials);
    } catch (_) {
      result = List.filled(indices.length, false);
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      for (var i = 0; i < indices.length && i < result.length; i++) {
        _results[indices[i]] = result[i];
      }
      _retryIndices = _results
          .mapIndexed((i, v) => (v == false) ? i : null)
          .nonNulls
          .toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.title.checkin_result),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            Expanded(
              child: (_running)
                  ? Center(
                      child: FCircularProgress(
                        size: .xl,
                        style: .delta(iconStyle: .delta(color: colors.primary)),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const .symmetric(horizontal: 24),
                      child: Center(
                        child: Column(
                          spacing: 8,
                          mainAxisAlignment: .center,
                          children: [
                            Icon(
                              (isAllFailed || isError)
                                  ? LucideIcons.circleX
                                  : ((isAllSuccess)
                                        ? LucideIcons.circleCheck
                                        : LucideIcons.circleAlert),
                              color: (isAllFailed || isError)
                                  ? colors.destructive
                                  : ((isAllSuccess)
                                        ? Colors.green
                                        : colors.primary),
                              size: 45,
                            ),
                            Row(
                              spacing: 8,
                              crossAxisAlignment: .end,
                              mainAxisAlignment: .center,
                              children: [
                                Text(
                                  successCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: .bold,
                                    fontFamily: 'AlteDIN1451',
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  "/ ${_results.length}",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: .bold,
                                    fontFamily: 'AlteDIN1451',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              (isAllFailed || isError)
                                  ? t.submodule.cqupt_checkin.checkin_all_failed
                                  : ((isAllSuccess)
                                        ? t
                                              .submodule
                                              .cqupt_checkin
                                              .checkin_all_success
                                        : t
                                              .submodule
                                              .cqupt_checkin
                                              .checkin_partial_failed),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: .bold,
                              ),
                            ),
                            const FDivider(),
                            (isError)
                                ? Text(
                                    t
                                        .submodule
                                        .cqupt_checkin
                                        .checkin_fatal_error,
                                    style: TextStyle(
                                      color: colors.destructive,
                                      fontSize: 18,
                                    ),
                                  )
                                : FSelectTileGroup<int>(
                                    // 结果变化时重建以重置选中状态
                                    key: ValueKey(
                                      _results.map((e) => e.toString()).join(),
                                    ),
                                    control: .managed(
                                      initial: _retryIndices.toSet(),
                                      onChange: (value) {
                                        setState(() => _retryIndices = value);
                                      },
                                    ),
                                    label: Text(widget.platform.name),
                                    children: [
                                      for (var i = 0; i < _results.length; i++)
                                        FSelectTile.tile(
                                          title: Text(
                                            widget.credentials[i].name,
                                          ),
                                          value: i,
                                          enabled: _results[i] == false,
                                          suffix: (_results[i] == true)
                                              ? const Icon(
                                                  LucideIcons.circleCheck,
                                                  color: Colors.green,
                                                )
                                              : const Icon(
                                                  LucideIcons.circleX,
                                                  color: Colors.red,
                                                ),
                                        ),
                                    ],
                                  ),
                            const FDivider(),
                            (isAllSuccess)
                                ? null
                                : FButton(
                                    variant: .primary,
                                    size: .sm,
                                    onPress: (_retryIndices.isNotEmpty)
                                        ? () => _checkin(_retryIndices.toList())
                                        : null,
                                    prefix: const Icon(LucideIcons.rotateCcw),
                                    child: Text(
                                      t.submodule.cqupt_checkin.retry_checkin,
                                    ),
                                  ),
                            FButton(
                              variant: (isAllSuccess) ? .primary : .secondary,
                              size: .sm,
                              onPress: () => context.pop(),
                              child: Text(t.notice.confirm),
                            ),
                          ].nonNulls.toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
