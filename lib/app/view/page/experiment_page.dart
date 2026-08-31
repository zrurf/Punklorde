import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/core/status/experiment.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

/// 实验性功能设置页
class ExperimentPage extends SignalStatefulWidget {
  const ExperimentPage({super.key});

  @override
  State<StatefulWidget> createState() => _ExperimentPageState();
}

class _ExperimentPageState extends State<ExperimentPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: Text(t.setting.experiment),
              prefixes: [FHeaderAction.back(onPress: () => context.pop())],
            ),
            Expanded(
              child: ListView(
                padding: const .symmetric(horizontal: 16, vertical: 8),
                children: [
                  FTileGroup(
                    label: Text(t.setting.experiment),
                    children: [
                      for (final feat in experimentFeatures)
                        FTile(
                          title: Text(feat.name),
                          subtitle: Text(
                            feat.desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                          details: FSwitch(
                            value: isExperimentEnabled(feat.id),
                            onChange: (v) => setExperimentEnabled(feat.id, v),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const .only(top: 4, left: 4),
                    child: Text(
                      t.setting.experiment_hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
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