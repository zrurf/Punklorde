import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/model/scanner.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/scanner/view/scanner.dart';
import 'package:punklorde/module/feature/tronclass/config.dart';
import 'package:punklorde/module/feature/tronclass/service.dart';
import 'package:punklorde/module/feature/tronclass/utils/link_parse.dart';
import 'package:signals/signals_flutter.dart';

/// 底部面板中可选的签到方式
enum _CheckinMode { course, universal }

/// 弹出签到方式选择面板，并按选择执行对应签到流程
Future<void> showCourseCheckinSheet(
  BuildContext context, {
  required TronclassConfig config,
  required String rollcallId,
  required String courseTitle,
}) async {
  final mode = await showFSheet<_CheckinMode>(
    context: context,
    builder: (sheetContext) => _CourseCheckinSheet(
      courseTitle: courseTitle,
      config: config,
      rollcallId: rollcallId,
    ),
    side: .btt,
  );
  if (!context.mounted) return;
  switch (mode) {
    case _CheckinMode.course:
      await _openCourseQrCheckin(context, config, rollcallId);
    case _CheckinMode.universal:
      await context.push('/p/universal_scan');
    case null:
      break;
  }
}

/// 打开跨课程扫码签到页
Future<void> _openCourseQrCheckin(
  BuildContext context,
  TronclassConfig config,
  String rollcallId,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) =>
          CourseQrCheckinPage(config: config, rollcallId: rollcallId),
    ),
  );
}

/// 签到方式选择底部面板
///
/// 参考 [InfoPanel] 的卡片式列表布局（见 lib/core/account/view/widget/info_panel.dart）。
class _CourseCheckinSheet extends StatelessWidget {
  final String courseTitle;
  final TronclassConfig config;
  final String rollcallId;

  const _CourseCheckinSheet({
    required this.courseTitle,
    required this.config,
    required this.rollcallId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          height: .infinity,
          width: .infinity,
          decoration: BoxDecoration(
            color: colors.background,
            border: .symmetric(horizontal: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            padding: const .symmetric(horizontal: 16, vertical: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    spacing: 2,
                    children: [
                      Text(
                        t.submodule.cqupt_checkin.qrcode_checkin,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                      Text(
                        config.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: .bold,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    courseTitle,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                    maxLines: 2,
                  ),
                  const FDivider(),
                  FTile(
                    title: Text(t.submodule.cqupt_checkin.course_scan_checkin),
                    subtitle: Text(
                      t.submodule.cqupt_checkin.course_scan_checkin_hint(
                        course: courseTitle,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                    prefix: Icon(LucideIcons.qrCode, color: colors.primary),
                    details: const Icon(LucideIcons.chevronRight),
                    onPress: () =>
                        Navigator.of(context).pop(_CheckinMode.course),
                  ),
                  FTile(
                    title: Text(
                      t.submodule.cqupt_checkin.universal_scan_checkin,
                    ),
                    subtitle: Text(
                      t.submodule.cqupt_checkin.universal_scan_checkin_hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                    prefix: Icon(LucideIcons.scanLine, color: colors.primary),
                    details: const Icon(LucideIcons.chevronRight),
                    onPress: () =>
                        Navigator.of(context).pop(_CheckinMode.universal),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 跨课程扫码签到页
///
/// 用「本课程的签到记录 ID + 扫描二维码中的 data 字段」上报签到，
/// 使任意课程的签到二维码都能为本课程签到。
class CourseQrCheckinPage extends StatelessWidget {
  final TronclassConfig config;
  final String rollcallId;

  const CourseQrCheckinPage({
    super.key,
    required this.config,
    required this.rollcallId,
  });

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
        bottomBarBuilder: _buildBottomBar,
        onResult: (result, controller) async {
          await _handleScanResult(context, result);
          if (context.mounted) {
            controller.resume();
          }
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ScannerController controller) {
    return SafeArea(
      child: Container(
        height: 120,
        padding: const .only(bottom: 30),
        child: SignalBuilder(
          builder: (context) => Row(
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
                      onTap: () => context.push('/p/checkin_user'),
                      isActive: false,
                    )
                  : const SizedBox(width: 60),
            ].nonNulls.toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleScanResult(BuildContext context, dynamic result) async {
    final decoded = (result is String && result.startsWith('/j?p='))
        ? TronClassSignDecoder.decode(result)
        : null;
    if (decoded == null || decoded["data"] == null) {
      _showError(context, Text(t.notice.invalid_qr_code));
      return;
    }

    final credentials = checkinAuthSignal.value
        .toList()
        .map((v) {
          final cred = authCredentials.value[v];
          return (cred?.type == config.platformId) ? cred : null;
        })
        .nonNulls
        .toList();
    if (credentials.isEmpty) {
      _showError(context, Text(t.notice.unselected_user));
      return;
    }

    await TronclassCheckinService(
      config,
    ).checkinQr(context, credentials, rollcallId, decoded["data"]);
  }

  void _showError(BuildContext context, Widget title) {
    showFToast(
      context: context,
      variant: .destructive,
      alignment: .topCenter,
      title: title,
      duration: const Duration(seconds: 3),
      icon: const Icon(LucideIcons.circleX),
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
