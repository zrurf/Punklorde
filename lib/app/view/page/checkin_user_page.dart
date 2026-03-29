import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:signals/signals_flutter.dart';

final Signal<String> _searchQuery = Signal('');

class CheckinUserPage extends StatefulWidget {
  const CheckinUserPage({super.key});

  @override
  State<StatefulWidget> createState() => _CheckinUserPageState();
}

class _CheckinUserPageState extends State<CheckinUserPage> {
  final GlobalKey<_CheckinUserPageState> widgetKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final entries =
        (authIndexGuest.watch(context).isEmpty &&
            authIndexPrimary.watch(context).isEmpty)
        ? null
        : currentSchoolSignal.value?.platforms.values
              .map((v) {
                final plat = authIndexGuest.watch(context)[v.id];
                final primary = authIndexPrimary.watch(context)[v.id];
                if ((plat == null || plat.isEmpty) && primary == null) {
                  return null;
                }
                final users = [
                  primary,
                  ...(plat?.values ?? []),
                ].nonNulls.toList();

                final u = users
                    .map((v1) {
                      final credential = authCredentials.watch(context)[v1];
                      if (credential == null) return null;
                      final searchStr = _searchQuery.watch(context);
                      final filter =
                          (searchStr.isEmpty ||
                              credential.name.toLowerCase().contains(
                                searchStr,
                              ) ||
                              credential.id.toLowerCase().contains(
                                searchStr,
                              )) ||
                          v.name.contains(searchStr);
                      return (filter)
                          ? FSelectTile.tile(
                              title: Row(
                                spacing: 8,
                                children: [
                                  Text(credential.name),
                                  FBadge(
                                    variant: (credential.guest)
                                        ? .outline
                                        : .primary,
                                    child: Text(
                                      (credential.guest)
                                          ? t.label.guest
                                          : t.label.primary,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              suffix: (credential.isValid())
                                  ? null
                                  : FBadge(
                                      variant: .destructive,
                                      child: Text(
                                        t.label.expired,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                              value: credential,
                            )
                          : null;
                    })
                    .nonNulls
                    .toList();

                return (u.isEmpty)
                    ? null
                    : FSelectTileGroup<AuthCredential>(
                        label: Text(v.name),
                        control: .managed(
                          initial: checkinAuthSignal.value,
                          onChange: (value) {
                            checkinAuthSignal.value = value;
                          },
                        ),
                        children: u,
                      );
              })
              .nonNulls
              .toList();

    late final List<Widget> result;

    if (entries == null) {
      result = [
        const FDivider(),
        Icon(LucideIcons.userRoundX, color: colors.primary, size: 24),
        Text(
          t.notice.no_guest,
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
      key: widgetKey,
      body: SafeArea(
        child: Column(
          spacing: 8,
          children: [
            FHeader.nested(
              title: Text(t.title.select_checkin_user),
              prefixes: [
                FHeaderAction.back(
                  onPress: () {
                    context.pop();
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
                hint: t.notice.search_user,
              ),
            ),

            Expanded(
              child: Padding(
                padding: const .symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: result.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const .symmetric(vertical: 8),
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
