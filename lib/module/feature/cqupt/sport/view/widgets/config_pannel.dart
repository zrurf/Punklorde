import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/resource/resource.dart';
import 'package:signals/signals_flutter.dart';

class ConfigPanel extends StatefulWidget {
  final void Function() onSelectMotionProfile;
  const ConfigPanel({super.key, required this.onSelectMotionProfile});

  @override
  State<StatefulWidget> createState() => _CanfigPanelState();
}

class _CanfigPanelState extends State<ConfigPanel> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: .infinity,
        width: .infinity,
        decoration: BoxDecoration(
          color: colors.background,
          border: .symmetric(horizontal: BorderSide(color: colors.border)),
        ),
        child: SingleChildScrollView(
          padding: const .symmetric(horizontal: 16, vertical: 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                spacing: 16,
                children: [
                  Text(
                    t.submodule.cqupt_sport.configure,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                  ),
                  const FDivider(),
                  FSelect.searchBuilder(
                    label: Text(t.submodule.cqupt_sport.motion_profile),
                    control: FSelectControl<ResourceIndexEntry>.managed(
                      initial: featMotionProfileIndex.watch(
                        context,
                      )?[featMotionProfile.watch(context)?.id],
                      onChange: (value) {
                        if (value != null) {
                          loadMotionProfile(value.id).then((v) {
                            if (v) {
                              widget.onSelectMotionProfile();
                            }
                          });
                        }
                      },
                    ),
                    format: (ResourceIndexEntry v) => v.name,
                    filter: (query) {
                      var lists =
                          featMotionProfileIndex.watch(context)?.values ?? [];
                      if (query.isEmpty) return lists;
                      return lists.where(
                        (v) => v.name.contains(query) || v.id.contains(query),
                      );
                    },
                    contentBuilder:
                        (
                          BuildContext context,
                          String query,
                          Iterable<ResourceIndexEntry> values,
                        ) => [
                          for (final v in values)
                            FSelectItem(title: Text(v.name), value: v),
                        ],
                  ),
                  // 目标距离
                  FTextFormField(
                    label: Text(t.submodule.cqupt_sport.distance),
                    description: Text(
                      t.submodule.cqupt_sport.cfg_distance_hint,
                    ),
                    keyboardType: .number,
                    control: .managed(
                      initial: TextEditingValue(
                        text: featUserConfig.value.targetDistance.toString(),
                      ),
                      onChange: (v) {
                        final value = double.tryParse(v.text);
                        if (v.text.isNotEmpty && value != null) {
                          featUserConfig.value = featUserConfig.value.copyWith(
                            targetDistance: value,
                          );
                        }
                      },
                    ),
                    autovalidateMode: .onUserInteraction,
                    validator: (value) =>
                        (value != null && double.tryParse(value) != null)
                        ? null
                        : t.submodule.cqupt_sport.input_invalid_hint,
                  ),
                  // 速度
                  FTextFormField(
                    label: Text(t.submodule.cqupt_sport.speed),
                    description: Text(t.submodule.cqupt_sport.cfg_speed_hint),
                    keyboardType: .number,
                    control: .managed(
                      initial: TextEditingValue(
                        text: featUserConfig.value.speed.toString(),
                      ),
                      onChange: (v) {
                        final value = double.tryParse(v.text);
                        if (value != null) {
                          featUserConfig.value = featUserConfig.value.copyWith(
                            speed: value,
                          );
                        }
                      },
                    ),
                    autovalidateMode: .onUserInteraction,
                    validator: (value) =>
                        (value != null && double.tryParse(value) != null)
                        ? null
                        : t.submodule.cqupt_sport.input_invalid_hint,
                  ),
                  // 抖动种子
                  FTextField(
                    label: Text(t.submodule.cqupt_sport.jitter_seed),
                    description: Text(
                      t.submodule.cqupt_sport.cfg_jitter_seed_hint,
                    ),
                    control: .managed(
                      initial: TextEditingValue(
                        text: featUserConfig.value.seed ?? '',
                      ),
                      onChange: (v) {
                        featUserConfig.value = featUserConfig.value.copyWith(
                          seed: (v.text.isEmpty) ? null : v.text,
                        );
                      },
                    ),
                  ),
                  // 刷新间隔
                  FTextFormField(
                    label: Text(t.submodule.cqupt_sport.update_interval),
                    keyboardType: .number,
                    control: .managed(
                      initial: TextEditingValue(
                        text: featUserConfig.value.interval.toString(),
                      ),
                      onChange: (v) {
                        final value = int.tryParse(v.text);
                        if (value != null) {
                          featUserConfig.value = featUserConfig.value.copyWith(
                            interval: value,
                          );
                        }
                      },
                    ),
                    autovalidateMode: .onUserInteraction,
                    validator: (value) =>
                        (value != null && int.tryParse(value) != null)
                        ? null
                        : t.submodule.cqupt_sport.input_invalid_hint,
                  ),
                  // 坐标抖动幅度
                  FTextFormField(
                    label: Text(t.submodule.cqupt_sport.jitter_pos),
                    description: Text(
                      t.submodule.cqupt_sport.cfg_pos_jitter_hint,
                    ),
                    keyboardType: .number,
                    control: .managed(
                      initial: TextEditingValue(
                        text: featUserConfig.value.positionJitterAmplitude
                            .toString(),
                      ),
                      onChange: (v) {
                        final value = double.tryParse(v.text);
                        if (value != null) {
                          featUserConfig.value = featUserConfig.value.copyWith(
                            positionJitterAmplitude: value,
                          );
                        }
                      },
                    ),
                    autovalidateMode: .onUserInteraction,
                    validator: (value) =>
                        (value != null && double.tryParse(value) != null)
                        ? null
                        : t.submodule.cqupt_sport.input_invalid_hint,
                  ),
                  // 速度抖动幅度
                  FTextFormField(
                    label: Text(t.submodule.cqupt_sport.jitter_speed),
                    description: Text(
                      t.submodule.cqupt_sport.cfg_speed_jitter_hint,
                    ),
                    keyboardType: .number,
                    control: .managed(
                      initial: TextEditingValue(
                        text: featUserConfig.value.speedJitterAmplitude
                            .toString(),
                      ),
                      onChange: (v) {
                        final value = double.tryParse(v.text);
                        if (value != null) {
                          featUserConfig.value = featUserConfig.value.copyWith(
                            speedJitterAmplitude: value,
                          );
                        }
                      },
                    ),
                    autovalidateMode: .onUserInteraction,
                    validator: (value) =>
                        (value != null && double.tryParse(value) != null)
                        ? null
                        : t.submodule.cqupt_sport.input_invalid_hint,
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
