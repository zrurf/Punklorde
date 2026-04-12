import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:punklorde/module/feature/scanner/view/scanner.dart';
import 'package:punklorde/module/feature/scanner/view/scanner_open_panel.dart';
import 'package:punklorde/common/model/scanner.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/code_handler.dart';
import 'package:signals/signals_flutter.dart';

class ScannerPage extends StatelessWidget {
  final ScanResultCallback? onResult;
  final ScannerBottomBarBuilder? bottomBarBuilder;

  const ScannerPage({super.key, this.onResult, this.bottomBarBuilder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScannerWidget(
        bottomBarBuilder: bottomBarBuilder,
        onResult: (result, controller) {
          // 标准页面逻辑：获取结果后直接关闭页面，不需要 resume
          onResult?.call(result, controller);
          context.pop(result);
        },
      ),
    );
  }
}

class UniversalScannerPage extends StatelessWidget {
  const UniversalScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScannerWidget(
        topBarButton: FButton.icon(
          size: .xs,
          variant: .ghost,
          child: const Icon(LucideIcons.x, color: Colors.white, size: 25),
          onPress: () => context.pop(),
        ),
        bottomBarBuilder: (context, controller) {
          return SafeArea(
            child: Container(
              height: 120,
              padding: const .only(bottom: 30),
              child: Watch(
                (context) => Row(
                  mainAxisAlignment: .spaceEvenly,
                  children: [
                    (!controller.isPaused)
                        ? _buildCircleButton(
                            context: context,
                            icon: LucideIcons.image,
                            onTap: controller.pickImage,
                          )
                        : const SizedBox(width: 60),
                    (!controller.isPaused)
                        ? _buildCircleButton(
                            context: context,
                            icon: LucideIcons.flashlight,
                            onTap: controller.toggleTorch,
                            isActive: controller.torchEnabled,
                          )
                        : const SizedBox(width: 60),
                    (!controller.isPaused)
                        ? _buildCircleButton(
                            context: context,
                            icon: LucideIcons.usersRound,
                            onTap: () {
                              context.push('/p/checkin_user');
                            },
                            isActive: false,
                          )
                        : const SizedBox(width: 60),
                  ].nonNulls.toList(),
                ),
              ),
            ),
          );
        },
        onResult: (result, controller) async {
          // 处理结果
          await _handleScanResult(context, result);

          // 当从结果页返回时，恢复扫描
          if (context.mounted) {
            controller.resume();
          }
        },
      ),
    );
  }

  /// 处理扫描结果
  Future<void> _handleScanResult(BuildContext context, dynamic result) async {
    final List<CodeHandler> candidates = [];

    for (final handler
        in currentSchoolSignal.value?.codeHandlers ?? <CodeHandler>{}) {
      if (handler.match(result)) {
        candidates.add(handler);
      }
    }

    if (candidates.length == 1 && candidates.first.immediatelyRedirect) {
      await candidates.first.handle(context, result);
      if (context.mounted) {
        context.pop();
      }
    } else {
      await _openDetailPage(context, result, candidates);
    }
  }

  Future<void> _openDetailPage(
    BuildContext context,
    dynamic result,
    List<CodeHandler> candidates,
  ) async {
    // 等待页面关闭
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _ResultDetailPage(result: result, candidates: candidates),
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withValues(alpha: 0.8)
              : Colors.black54,
          shape: .circle,
          border: .all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _ResultDetailPage extends StatelessWidget {
  final dynamic result;
  final List<CodeHandler> candidates;

  const _ResultDetailPage({required this.result, required this.candidates});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    late final String content;
    final bool isBin = (result is! String);

    if (result is String) {
      content = result;
    } else if (result is DecodedBarcodeBytes) {
      content = base64.encode((result as DecodedBarcodeBytes).bytes);
    } else {
      content = result.toString();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.title.scan_result),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const .symmetric(horizontal: 24),
                child: Center(
                  child: Column(
                    spacing: 4,
                    mainAxisAlignment: .center,
                    children: [
                      Icon(
                        LucideIcons.circleCheck,
                        color: colors.primary,
                        size: 45,
                      ),
                      const FDivider(),
                      Visibility(
                        visible: isBin,
                        child: FBadge(
                          child: Text(
                            t.common.binary,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      SelectableText(
                        content,
                        style: TextStyle(
                          fontSize: (isBin || content.length > 80) ? 15 : 18,
                          fontWeight: (isBin || content.length > 80)
                              ? .normal
                              : .bold,
                        ),
                        textAlign: .center,
                      ),
                      const FDivider(),
                      FButton(
                        variant: .primary,
                        size: .sm,
                        onPress: (candidates.isNotEmpty)
                            ? () async {
                                if (candidates.length == 1) {
                                  candidates.first.handle(context, result);
                                } else {
                                  await showFSheet(
                                    context: context,
                                    builder: (sheetContext) => ScannerOpenPanel(
                                      superContext: context,
                                      handlers: candidates,
                                      data: result,
                                      onClose: () {},
                                    ),
                                    side: .btt,
                                  );
                                }
                              }
                            : null,
                        prefix: const Icon(LucideIcons.externalLink),
                        child: (candidates.length == 1)
                            ? Text(
                                t.action.open_with_name(
                                  name: candidates.first.name,
                                ),
                              )
                            : Text(t.action.open_with),
                      ),
                      FButton(
                        variant: .secondary,
                        size: .sm,
                        prefix: const Icon(LucideIcons.arrowLeft),
                        onPress: () => context.pop(),
                        child: Text(t.notice.continue_scan),
                      ),
                    ],
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
