import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/registry/school.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

final Signal<String> _searchQuery = Signal('');
final _filteredSchools = computed(() {
  var query = _searchQuery.value.trim().toLowerCase();
  if (query.isEmpty) return getSchools();

  return getSchools().where((school) {
    return school.id.toLowerCase().contains(query) ||
        school.name.toLowerCase().contains(query) ||
        school.alias.contains(query);
  }).toList();
});

class SelectSchoolPageView extends StatelessWidget {
  const SelectSchoolPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final entries = _filteredSchools.watch(context).map((v) {
      return FTile(
        prefix: Image.asset(v.logo, width: 32, height: 32),
        title: Text(v.name),
        subtitle: Text(v.id.toUpperCase()),
        onPress: () {
          setCurrentSchool(v);
          context.go("/index/home");
        },
      );
    }).toList();

    late final List<Widget> result;

    if (entries.isEmpty) {
      result = [
        const FDivider(),
        Icon(LucideIcons.funnelX, color: colors.primary, size: 24),
        Text(
          t.notice.no_search_result,
          style: TextStyle(color: colors.mutedForeground, fontSize: 14),
          textAlign: .center,
        ),
      ];
    } else {
      result = entries;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          spacing: 8,
          children: [
            FHeader.nested(
              title: Text(t.title.select_school),
              prefixes: currentSchoolSignal.value != null
                  ? [
                      FHeaderAction.back(
                        onPress: () {
                          context.pop();
                        },
                      ),
                    ]
                  : [],
              style: .context(),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16),
              child: FTextField(
                enabled: true,
                control: .managed(
                  onChange: (v) {
                    _searchQuery.value = v.text;
                  },
                ),

                hint: t.notice.search_school,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const .symmetric(horizontal: 16),
                child: Watch(
                  (context) => ListView.builder(
                    itemCount: result.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const .symmetric(vertical: 4),
                        child: result[index],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
