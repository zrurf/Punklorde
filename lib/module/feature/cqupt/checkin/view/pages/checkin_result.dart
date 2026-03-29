import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/model/platform.dart';
import 'package:signals/signals_flutter.dart';

/// 签到结果页面
class CheckinResultPage extends StatefulWidget {
  final Platform platform;
  final List<AuthCredential> credentials;
  final List<bool> results;
  final Future<void> Function(List<AuthCredential>) onRetry;

  const CheckinResultPage({
    super.key,
    required this.platform,
    required this.credentials,
    required this.results,
    required this.onRetry,
  });

  @override
  State<StatefulWidget> createState() => _CheckinResultPageState();
}

class _CheckinResultPageState extends State<CheckinResultPage> {
  final Signal<Set<AuthCredential>> _retryList = signal({});

  late final bool isError;
  late final bool isAllSuccess;
  late final bool isAllFailed;
  late final int successCount;

  @override
  void initState() {
    super.initState();

    isError = widget.results.isEmpty;
    isAllSuccess = widget.results.every((e) => e);
    isAllFailed = widget.results.every((e) => !e);
    successCount = widget.results.where((e) => e).length;

    _retryList.value = widget.results
        .mapIndexed((i, v) => (v) ? null : widget.credentials[i])
        .nonNulls
        .toSet();
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
              child: SingleChildScrollView(
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
                            : ((isAllSuccess) ? Colors.green : colors.primary),
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
                            "/ ${widget.results.length}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: .bold,
                              fontFamily: 'AlteDIN1451',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        (isAllFailed)
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
                        style: const TextStyle(fontSize: 20, fontWeight: .bold),
                      ),
                      const FDivider(),
                      (isError)
                          ? Text(
                              t.submodule.cqupt_checkin.checkin_fatal_error,
                              style: TextStyle(
                                color: colors.destructive,
                                fontSize: 18,
                              ),
                            )
                          : FSelectTileGroup<AuthCredential>(
                              control: .managed(
                                initial: _retryList.value.toSet(),
                                onChange: (value) {
                                  _retryList.value = value;
                                },
                              ),
                              label: Text(widget.platform.name),
                              children: widget.results
                                  .mapIndexed(
                                    (index, value) => FSelectTile.tile(
                                      title: Text(
                                        widget.credentials[index].name,
                                      ),
                                      value: widget.credentials[index],
                                      enabled: !value,
                                      suffix: (value)
                                          ? const Icon(
                                              LucideIcons.circleCheck,
                                              color: Colors.green,
                                            )
                                          : const Icon(
                                              LucideIcons.circleX,
                                              color: Colors.red,
                                            ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      const FDivider(),
                      (isAllSuccess)
                          ? null
                          : FButton(
                              variant: .primary,
                              size: .sm,
                              onPress: (_retryList.watch(context).isNotEmpty)
                                  ? () async {
                                      await widget.onRetry(
                                        _retryList.value.toList(),
                                      );
                                      if (context.mounted) {
                                        context.pop();
                                      }
                                    }
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
