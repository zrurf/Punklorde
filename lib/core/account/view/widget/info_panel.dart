import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/utils/etc/clipboard.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals_flutter.dart';

class InfoPanel extends StatefulWidget {
  final AuthCredential credential;

  const InfoPanel({super.key, required this.credential});

  @override
  State<StatefulWidget> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<InfoPanel> {
  final Signal<Uint8List?> _shareData = signal(null);
  final Signal<QrCode?> _qrCode = signal(null);
  final Signal<bool> _qrBuildError = signal(false);

  @override
  void initState() {
    super.initState();

    widget.credential.toSharedData().then((v) {
      if (v == null) return;
      _shareData.value = v;
      if (v.length > 2500) {
        _qrBuildError.value = true;
        return;
      }
      _qrCode.value = QrCode.fromUint8List(
        data: v,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
    });
  }

  Future<void> _shareAsFile() async {
    final rawData = _shareData.value;
    if (rawData == null) {
      return;
    }
    try {
      // 分享文件
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(rawData)],
          fileNameOverrides: [
            '${t.app_name} ${t.action.share_code}_'
                '${currentSchoolSignal.value?.platforms[widget.credential.type]?.name}_'
                '${widget.credential.name}_${formatFileNameDate(DateTime.now())}.pkld',
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          alignment: .topCenter,
          icon: const Icon(LucideIcons.circleX),
          title: Text(t.notice.share_failed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final platform = currentSchoolSignal
        .watch(context)
        ?.platforms[widget.credential.type];
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
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                spacing: 8,
                children: [
                  Row(
                    spacing: 2,
                    children: [
                      Text(
                        t.title.already_login,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                      Text(
                        (platform == null)
                            ? t.title.unknown_platform
                            : platform.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: .bold,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Text(
                        widget.credential.name,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: .bold,
                          color: colors.foreground,
                        ),
                        maxLines: 2,
                      ),
                      (widget.credential.guest)
                          ? FBadge(
                              variant: .primary,
                              child: Text(
                                t.label.guest,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          : null,
                    ].nonNulls.toList(),
                  ),
                  FDivider(),
                  SizedBox(
                    width: 450,
                    child: Column(
                      spacing: 8,
                      children: [
                        FTile(
                          title: Text(t.action.login_info),
                          prefix: Icon(
                            LucideIcons.fileUser,
                            color: colors.primary,
                          ),
                          suffix: Icon(LucideIcons.chevronRight),
                          onPress: () {
                            showFDialog(
                              context: context,
                              builder: (context, style, animation) => FDialog(
                                style: style,
                                animation: animation,
                                title: Text(t.action.login_info),
                                body: Column(
                                  spacing: 4,
                                  mainAxisSize: .min,
                                  children: [
                                    _buildInfoField(
                                      context,
                                      title: t.title.user,
                                      value: widget.credential.name,
                                      icon: LucideIcons.user,
                                      onLongPress: () {
                                        copyToClipboard(widget.credential.name);
                                      },
                                    ),
                                    _buildInfoField(
                                      context,
                                      title: t.title.id,
                                      value: widget.credential.id,
                                      icon: LucideIcons.key,
                                      onLongPress: () {
                                        copyToClipboard(widget.credential.id);
                                      },
                                    ),
                                    _buildInfoField(
                                      context,
                                      title: t.title.exprire_at,
                                      value: DateFormat(
                                        'yyyy-MM-dd HH:mm:ss',
                                      ).format(widget.credential.expireAt),
                                      icon: LucideIcons.history,
                                      onLongPress: () {},
                                    ),
                                  ],
                                ),
                                actions: [
                                  FButton(
                                    size: .xs,
                                    onPress: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(t.notice.confirm),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        (!widget.credential.guest)
                            ? FTile(
                                title: Text(t.action.share_code),
                                prefix: Icon(
                                  LucideIcons.qrCode,
                                  color: colors.primary,
                                ),
                                suffix: Icon(LucideIcons.chevronRight),
                                onPress: () {
                                  if (widget.credential.guest) {
                                    return;
                                  }
                                  showFDialog(
                                    context: context,
                                    builder: (context, style, animation) {
                                      final colors = context.theme.colors;
                                      final qrCode = _qrCode.watch(context);
                                      return FDialog(
                                        style: style,
                                        animation: animation,
                                        title: Text(t.action.share_code),
                                        body: (qrCode == null)
                                            ? ((_qrBuildError.watch(context))
                                                  ? Column(
                                                      spacing: 4,
                                                      mainAxisSize: .min,
                                                      children: [
                                                        Icon(
                                                          LucideIcons
                                                              .circleAlert,
                                                          color: colors.error,
                                                        ),
                                                        Text(
                                                          t
                                                              .notice
                                                              .share_qr_render_error,
                                                          style: TextStyle(
                                                            color: colors.error,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : FCircularProgress(
                                                      size: .xl,
                                                      style: .delta(
                                                        iconStyle: .delta(
                                                          color: colors.primary,
                                                        ),
                                                      ),
                                                    ))
                                            : QrImageView.withQr(
                                                qr: qrCode,
                                                backgroundColor: Colors.white,
                                                errorStateBuilder:
                                                    (context, error) => Column(
                                                      spacing: 4,
                                                      mainAxisSize: .min,
                                                      children: [
                                                        Icon(
                                                          LucideIcons
                                                              .circleAlert,
                                                          color: colors.error,
                                                        ),
                                                        Text(
                                                          t
                                                              .notice
                                                              .share_qr_render_error,
                                                          style: TextStyle(
                                                            color: colors.error,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                        actions: [
                                          FButton(
                                            variant: .secondary,
                                            size: .xs,
                                            onPress:
                                                (_shareData.watch(context) !=
                                                    null)
                                                ? () {
                                                    _shareAsFile();
                                                  }
                                                : null,
                                            prefix: const Icon(
                                              LucideIcons.fileUp,
                                            ),
                                            child: Text(t.action.file_sharing),
                                          ),
                                          FButton(
                                            size: .xs,
                                            onPress: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(t.notice.confirm),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              )
                            : null,
                        FTile(
                          title: Text(t.action.refresh_login),
                          prefix: Icon(
                            LucideIcons.refreshCcw,
                            color: colors.primary,
                          ),
                          onPress: () async {
                            if (platform != null) {
                              context.loaderOverlay.show();
                              final result = await authManager
                                  .refreshByCredential(widget.credential);
                              if (context.mounted) {
                                context.loaderOverlay.hide();
                                showFToast(
                                  context: context,
                                  variant: (result) ? .primary : .destructive,
                                  alignment: .topCenter,
                                  title: Text(
                                    (result)
                                        ? t.notice.refresh_success
                                        : t.notice.refresh_failed,
                                  ),
                                  description: (result)
                                      ? null
                                      : Text(t.notice.refresh_failed_hint),
                                  duration: const Duration(seconds: 3),
                                  icon: (result)
                                      ? const Icon(LucideIcons.circleCheck)
                                      : const Icon(LucideIcons.circleX),
                                );
                                Navigator.of(context).pop();
                              }
                            }
                          },
                        ),
                        FTile(
                          title: Text(
                            (widget.credential.isValid())
                                ? t.action.logout
                                : t.action.re_login,
                            style: TextStyle(color: colors.error),
                          ),
                          prefix: Icon(LucideIcons.logOut, color: colors.error),
                          onPress: () {
                            if (platform != null) {
                              authManager.logoutByCredential(widget.credential);
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ].nonNulls.toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required void Function()? onLongPress,
  }) {
    final colors = context.theme.colors;
    return FItem(
      title: Text(
        title,
        style: TextStyle(color: colors.mutedForeground, fontSize: 14),
      ),
      details: Text(
        value,
        style: TextStyle(color: colors.foreground, fontSize: 14),
        maxLines: 3,
        textAlign: .end,
      ),
      prefix: Icon(icon),
      onLongPress: onLongPress,
    );
  }
}
