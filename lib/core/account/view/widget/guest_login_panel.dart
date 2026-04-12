import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/account/code_handler.dart';
import 'package:punklorde/core/account/view/page/select_platform.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';

class GuestLoginPanel extends StatefulWidget {
  const GuestLoginPanel({super.key});

  @override
  State<StatefulWidget> createState() => _GuestLoginPanelState();
}

class _GuestLoginPanelState extends State<GuestLoginPanel> {
  final GlobalKey<_GuestLoginPanelState> widgetKey = GlobalKey();

  Future<Uint8List?> pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pkld', 'bin'],
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      final data = file.bytes;
      if (data == null) throw Exception('Failed to read file');
      return file.bytes;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      key: widgetKey,
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
                  Text(
                    t.title.add_guest,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                  ),
                  FDivider(),
                  SizedBox(
                    width: 450,
                    child: Column(
                      spacing: 8,
                      children: [
                        FTile(
                          title: Text(t.action.guest_add_by_login),
                          prefix: Icon(
                            LucideIcons.keyRound,
                            color: colors.primary,
                          ),
                          suffix: Icon(LucideIcons.chevronRight),
                          onPress: () async {
                            final result = await showFSheet(
                              context: context,
                              builder: (sheetContext) => SelectPlatformPage(),
                              side: .btt,
                            );

                            if (result != null && context.mounted) {
                              final newCredential = await result.login(
                                context,
                                true,
                              );
                              if (newCredential != null) {
                                setAuthCredential(newCredential);
                              }
                              if (context.mounted) {
                                showFToast(
                                  context: context,
                                  variant: (newCredential != null)
                                      ? .primary
                                      : .destructive,
                                  alignment: .topCenter,
                                  title: (newCredential != null)
                                      ? Text(t.notice.login_success)
                                      : Text(t.notice.login_failed),
                                  description: Text(result.name),
                                  duration: const Duration(seconds: 3),
                                  icon: (newCredential != null)
                                      ? const Icon(LucideIcons.circleCheck)
                                      : const Icon(LucideIcons.circleX),
                                );
                              }
                            }
                          },
                        ),
                        FTile(
                          title: Text(t.action.guest_add_by_code),
                          prefix: Icon(
                            LucideIcons.scanQrCode,
                            color: colors.primary,
                          ),
                          suffix: Icon(LucideIcons.chevronRight),
                          onPress: () async {
                            await context.push('/p/scan').then((v) async {
                              final context = widgetKey.currentContext;
                              if (v == null) return;
                              if (handlerGuestAccount.match(v) &&
                                  context != null &&
                                  context.mounted) {
                                await handlerGuestAccount.handle(context, v);
                              } else {
                                if (context != null && context.mounted) {
                                  showFToast(
                                    context: context,
                                    variant: .destructive,
                                    alignment: .topCenter,
                                    title: Text(t.notice.invalid_qr_code),
                                    duration: const Duration(seconds: 3),
                                    icon: const Icon(LucideIcons.circleX),
                                  );
                                  Navigator.of(context).pop();
                                }
                              }
                            });
                          },
                        ),
                        FTile(
                          title: Text(t.action.guest_add_by_file),
                          prefix: Icon(
                            LucideIcons.fileUser,
                            color: colors.primary,
                          ),
                          suffix: Icon(LucideIcons.chevronRight),
                          onPress: () async {
                            try {
                              final data = pickAndReadFile();
                              if (handlerGuestAccount.match(data) &&
                                  context.mounted) {
                                await handlerGuestAccount.handle(context, data);
                              } else {
                                if (context.mounted) {
                                  showFToast(
                                    context: context,
                                    variant: .destructive,
                                    alignment: .topCenter,
                                    title: Text(t.notice.invalid_data),
                                    duration: const Duration(seconds: 3),
                                    icon: const Icon(LucideIcons.circleX),
                                  );
                                  Navigator.of(context).pop();
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showFToast(
                                  context: context,
                                  variant: .destructive,
                                  alignment: .topCenter,
                                  title: Text(t.notice.failed_open_file),
                                  description: Text(e.toString()),
                                  duration: const Duration(seconds: 3),
                                  icon: const Icon(LucideIcons.circleX),
                                );
                              }
                            }
                          },
                        ),
                      ],
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
}
