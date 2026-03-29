import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/module/model/feature.dart';
import 'package:punklorde/module/model/school.dart';

final SchoolTab tabSchedule = SchoolTab(
  id: 'common_schedule',
  name: '日程',
  widget: (BuildContext context) {
    return Container();
  },
);

SchoolTab tabFunctions(List<Feature> feats) => SchoolTab(
  id: 'common_func',
  name: '工作台',
  widget: (BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const .symmetric(horizontal: 16),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 80,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: feats.length,
            itemBuilder: (context, index) =>
                _buildFeatBox(context, feats[index]),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
          ),
        ),
      ),
    );
  },
);

Widget _buildFeatBox(BuildContext context, Feature feat) {
  return FTappable(
    onPress: () => feat.action(context),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FTappable(
          child: Container(
            width: 48,
            height: 48,
            padding: .all(8),
            decoration: BoxDecoration(
              color: feat.bgColor,
              borderRadius: .circular(12),
            ),
            child: feat.icon,
          ),
        ),

        const SizedBox(height: 4),
        Text(
          feat.name,
          style: const TextStyle(fontSize: 12),
          softWrap: true,
          overflow: .ellipsis,
          textAlign: .center,
          maxLines: 2,
        ),
      ],
    ),
  );
}
