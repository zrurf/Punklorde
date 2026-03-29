import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/constant/meta.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
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

class ProfileView extends StatelessWidget {
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
                  suffix: Icon(
                    _themeIcon.watch(context),
                    color: colors.primary,
                  ),
                  onPress: () {
                    cycleThemeMode();
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
                      builder: (context, style, animation) => FDialog(
                        style: style,
                        animation: animation,
                        title: Text(t.setting.about),
                        body: Column(
                          mainAxisSize: .min,
                          children: [
                            Text(
                              t.app_name,
                              style: TextStyle(fontSize: 20, fontWeight: .bold),
                              textAlign: .center,
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
