import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:forui/forui.dart';
import 'package:punklorde/utils/etc/fdialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/constant/meta.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/map.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/service/lbs/map.dart';
import 'package:punklorde/utils/etc/url.dart';
import 'package:signals/signals_flutter.dart';

final Computed<IconData> _themeIcon = Computed(() {
  switch (themeModeSignal.value) {
    case .system:
      return LucideIcons.eclipse;
    case .light:
      return LucideIcons.sun;
    case .dark:
      return LucideIcons.moon;
  }
});

/// 关于弹窗中的信息行
class _AboutInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: colors.mutedForeground),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class ProfileView extends SignalWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const .symmetric(vertical: 8, horizontal: 16),
        child: Column(
          spacing: 8,
          children: [
            FTileGroup(
              label: Text(t.common.common),
              children: [
                FTile(
                  title: Text(t.setting.sources_list),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    context.push('/s/sources_list');
                  },
                ),
                FTile(
                  title: Text(t.setting.dl_cache),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    context.push('/s/dl_cache');
                  },
                ),
                FTile(
                  title: Text(t.title.change_school),
                  onPress: () {
                    context.push('/p/select_school');
                  },
                ),
                FTile(
                  title: Text(t.setting.theme),
                  suffix: Icon(_themeIcon.value, color: colors.primary),
                  onPress: () {
                    cycleThemeMode();
                  },
                ),
                FTile(
                  title: Text(t.setting.map_provider),
                  suffix: Icon(LucideIcons.map, color: colors.primary),
                  onPress: () {
                    showFDialog(
                      context: context,
                      builder: (context, style, animation) => punklordeDialog(
                        style: style,
                        animation: animation,
                        title: Text(t.setting.map_provider),
                        body: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final provider in availableMapProviders)
                              FTile(
                                title: Text(provider.displayName),
                                details: (mapProviderSignal.value == provider)
                                    ? Icon(
                                        LucideIcons.check,
                                        color: colors.primary,
                                      )
                                    : null,
                                onPress: () {
                                  setMapProvider(provider);
                                  Navigator.of(context).pop();
                                },
                              ),
                          ],
                        ),
                        actions: [
                          FButton(
                            size: .xs,
                            onPress: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(t.notice.cancel),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                FTile(
                  title: Text(t.setting.language),
                  suffix: Icon(LucideIcons.languages, color: colors.primary),
                  onPress: () {
                    showFDialog(
                      context: context,
                      builder: (context, style, animation) => punklordeDialog(
                        style: style,
                        animation: animation,
                        title: Text(t.setting.language),
                        body: SingleChildScrollView(
                          child: FTileGroup(
                            children: [
                              for (final option in const <(String, String?)>[
                                ("English", "en"),
                                ("简体中文", "zh_CN"),
                              ])
                                FTile(
                                  title: Text(option.$1),
                                  details: (localeSignal.value == option.$2)
                                      ? Icon(
                                          LucideIcons.check,
                                          color: colors.primary,
                                        )
                                      : null,
                                  onPress: () {
                                    setLocale(option.$2);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              FTile(
                                title: Text(t.setting.follow_system),
                                details: (localeSignal.value == null)
                                    ? Icon(
                                        LucideIcons.check,
                                        color: colors.primary,
                                      )
                                    : null,
                                onPress: () {
                                  setLocale(null);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          FButton(
                            size: .xs,
                            onPress: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(t.notice.cancel),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                FTile(
                  title: Text(t.setting.experiment),
                  suffix: const Icon(
                    LucideIcons.flaskConical,
                    color: Colors.orange,
                  ),
                  onPress: () {
                    context.push('/s/experiment');
                  },
                ),
              ],
            ),
            FTileGroup(
              label: Text(t.common.account),
              children: [
                FTile(
                  title: Text(t.setting.primary_account),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    context.push('/s/account/primary');
                  },
                ),
                FTile(
                  title: Text(t.setting.guest_account),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    context.push('/s/account/guest');
                  },
                ),
                FTile(
                  title: Text(t.setting.password_vault),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    context.push('/s/pwd_vault');
                  },
                ),
              ],
            ),
            FTileGroup(
              label: Text(t.setting.about),
              children: [
                FTile(
                  title: Text(t.setting.about),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    showFDialog(
                      context: context,
                      builder: (context, style, animation) => punklordeDialog(
                        style: style,
                        animation: animation,
                        title: Text(
                          t.setting.about,
                          textAlign: .center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: .bold,
                          ),
                        ),
                        body: Column(
                          mainAxisSize: .min,
                          spacing: 4,
                          children: [
                            Text(
                              t.app_name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: .bold,
                              ),
                              textAlign: .center,
                            ),
                            const SizedBox(height: 8),
                            _AboutInfoRow(
                              label: t.setting.build_date,
                              value: buildDate,
                            ),
                            _AboutInfoRow(
                              label: t.setting.git_commit,
                              value: gitCommit,
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
                FTile(
                  title: Text(t.setting.license),
                  suffix: const Icon(LucideIcons.chevronRight),
                  onPress: () {
                    context.push('/s/license');
                  },
                ),
                FTile(
                  title: Text(t.setting.github_link),
                  suffix: const Icon(LucideIcons.link),
                  onPress: () {
                    launchInBrowser(projGithubUrl);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
