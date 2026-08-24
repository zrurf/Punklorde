import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/manifest.dart';

/// 重邮智慧体育 - 关于
class FeatSportCquptAboutView extends StatelessWidget {
  const FeatSportCquptAboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.submodule.cqupt_sport.about),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            Expanded(
              child: ListView(
                padding: const .symmetric(horizontal: 16, vertical: 8),
                children: [
                  FCard(
                    child: Padding(
                      padding: const .all(4),
                      child: Padding(
                        padding: const .all(8),
                        child: Column(
                          crossAxisAlignment: .start,
                          spacing: 4,
                          children: [
                            Text(
                              featSportCqupt.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: .bold,
                                color: colors.foreground,
                              ),
                            ),
                            Text(
                              'version ${featSportCqupt.version}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 设置项
                  FTileGroup(
                    label: Text(t.common.setting),
                    children: [
                      FTile(
                        prefix: Icon(LucideIcons.route),
                        title: Text(t.submodule.cqupt_sport.recorded_tracks),
                        subtitle: Text(
                          t.submodule.cqupt_sport.recorded_tracks_hint,
                        ),
                        suffix: const Icon(LucideIcons.chevronRight),
                        onPress: () {
                          context.push("/feat/cqupt/sport/tracks");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
