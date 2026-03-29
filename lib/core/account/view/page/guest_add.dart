import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/utils/time.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter.dart' hide signal;

class GuestAddPage extends StatefulWidget {
  final dynamic data;
  const GuestAddPage({super.key, required this.data});

  @override
  State<StatefulWidget> createState() => _GuestAddPageState();
}

class _GuestAddPageState extends State<GuestAddPage> {
  final GlobalKey<_GuestAddPageState> widgetKey = GlobalKey();

  final Signal<AuthCredential?> credential = signal(null);
  final Signal<String?> error = signal(null);
  final Signal<bool> isExist = signal(false);

  Future<void> _init() async {
    try {
      if (widget.data is! DecodedBarcodeBytes) {
        throw Exception(t.notice.invalid_data);
      }
      final cred = await AuthCredential.fromSharedData(widget.data.bytes);
      if (cred == null) throw Exception(t.notice.invalid_data);
      credential.value = cred.copyWith(guest: true);
      isExist.value = authManager.hasGuest(credential.value!);
    } catch (e) {
      error.value = t.notice.invalid_data;
      return;
    }
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      key: widgetKey,
      body: Column(
        children: [
          FHeader.nested(
            title: Text(t.title.add_guest),
            prefixes: [FHeaderAction.x(onPress: () => context.pop())],
          ),
          SingleChildScrollView(
            padding: const .all(24),
            child: Center(
              child: Column(
                spacing: 8,
                mainAxisAlignment: .center,
                children: [
                  Icon(
                    (error.watch(context) == null)
                        ? ((isExist.value)
                              ? LucideIcons.circleCheck
                              : LucideIcons.userRoundPlus)
                        : LucideIcons.circleX,
                    color: (error.watch(context) == null)
                        ? colors.primary
                        : colors.error,
                    size: 50,
                  ),
                  Visibility(
                    visible: isExist.watch(context),
                    child: Text(
                      t.notice.current_guest_exist,
                      style: TextStyle(
                        fontSize: 20,
                        color: colors.primary,
                        fontWeight: .bold,
                      ),
                    ),
                  ),
                  FDivider(),
                  SingleChildScrollView(
                    child: Column(
                      spacing: 8,
                      children: (credential.watch(context) != null)
                          ? [
                              _buildInfoField(
                                context,
                                title: t.title.platform,
                                value:
                                    currentSchoolSignal
                                        .watch(context)
                                        ?.platforms[credential
                                            .watch(context)
                                            ?.type]
                                        ?.name ??
                                    t.title.unknown_platform,
                                icon: LucideIcons.layers2,
                              ),
                              _buildInfoField(
                                context,
                                title: t.title.user,
                                value: credential.watch(context)?.name ?? "?",
                                icon: LucideIcons.userRound,
                              ),
                              _buildInfoField(
                                context,
                                title: t.title.id,
                                value: credential.watch(context)?.id ?? "?",
                                icon: LucideIcons.key,
                              ),
                              _buildInfoField(
                                context,
                                title: t.title.exprire_at,
                                value: formatDate(
                                  credential.watch(context)?.expireAt ??
                                      DateTime.now(),
                                ),
                                icon: LucideIcons.history,
                              ),
                            ]
                          : ((error.watch(context) != null)
                                ? [
                                    FCircularProgress(
                                      size: .xl,
                                      style: .delta(
                                        iconStyle: .delta(
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  ]
                                : [
                                    Text(
                                      error.watch(context) ?? "",
                                      style: TextStyle(color: colors.error),
                                    ),
                                  ]),
                    ),
                  ),
                  FDivider(),
                  FButton(
                    onPress: (credential.watch(context) != null)
                        ? () async {
                            final context = widgetKey.currentContext;
                            if (credential.value == null) return;
                            authManager.addGuest(credential.value!);
                            if (context != null && context.mounted) {
                              await showFDialog(
                                context: context,
                                builder: (sheetContext, style, animation) =>
                                    FDialog(
                                      style: style,
                                      animation: animation,
                                      title: Text(t.title.add_guest),
                                      body: Column(
                                        spacing: 8,
                                        mainAxisSize: .min,
                                        children: [
                                          Icon(
                                            LucideIcons.circleCheck,
                                            size: 30,
                                            color: colors.primary,
                                          ),
                                          Text(
                                            t.common.success,
                                            style: TextStyle(
                                              color: colors.foreground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        FButton(
                                          size: .xs,
                                          onPress: () {
                                            Navigator.of(sheetContext).pop();
                                          },
                                          child: Text(t.notice.confirm),
                                        ),
                                      ],
                                    ),
                              );
                              if (context.mounted) {
                                context.pop();
                              }
                            }
                          }
                        : null,
                    prefix: const Icon(LucideIcons.plus),
                    child: (isExist.watch(context))
                        ? Text(t.action.re_add_guest)
                        : Text(t.action.add_guest),
                  ),
                  FButton(
                    variant: .secondary,
                    size: .sm,
                    prefix: const Icon(LucideIcons.arrowLeft),
                    onPress: () => context.pop(),
                    child: Text(t.action.back),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return FTextField(
      label: Row(spacing: 4, children: [Icon(icon, size: 20), Text(title)]),
      control: .lifted(
        value: TextEditingValue(text: value),
        onChange: (v) {},
      ),
      readOnly: true,
    );
  }
}
