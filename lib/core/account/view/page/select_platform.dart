import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';

final Signal<String> _searchQuery = Signal('');
final _filteredPlats = computed(() {
  final platforms = currentSchoolSignal.value?.platforms.values ?? [];
  var query = _searchQuery.value.trim().toLowerCase();
  if (query.isEmpty) return (platforms.isNotEmpty) ? platforms : null;

  final result = platforms.where((plat) {
    return plat.id.toLowerCase().contains(query) ||
        plat.name.toLowerCase().contains(query);
  }).toList();

  return result;
});

class SelectPlatformPage extends StatefulWidget {
  const SelectPlatformPage({super.key});

  @override
  State<StatefulWidget> createState() => _SelectPlatformPageState();
}

class _SelectPlatformPageState extends State<SelectPlatformPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final entries = _filteredPlats.watch(context)?.map((v) {
      return FTile(
        title: Text(v.name),
        suffix: Icon(LucideIcons.chevronRight),
        onPress: () {
          Navigator.of(context).pop(v);
        },
      );
    }).toList();

    late final List<Widget> result;

    if (entries == null) {
      result = [
        const FDivider(),
        Icon(LucideIcons.ban, color: colors.primary, size: 24),
        Text(
          t.notice.no_avaliable_plat,
          style: TextStyle(color: colors.mutedForeground, fontSize: 14),
          textAlign: .center,
        ),
      ];
    } else if (entries.isEmpty) {
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
              title: Text(t.title.select_platform),
              prefixes: [
                FHeaderAction.back(
                  onPress: () {
                    Navigator.of(context).pop(null);
                  },
                ),
              ],
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
                hint: t.notice.search_platform,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const .symmetric(horizontal: 16),
                child: ListView.builder(
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
          ],
        ),
      ),
    );
  }
}
