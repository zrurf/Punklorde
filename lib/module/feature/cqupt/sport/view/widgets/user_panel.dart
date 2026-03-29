import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/sport.dart';
import 'package:signals/signals_flutter.dart';

final String _platId = platCquptSport.id;

final Signal<String> _searchQuery = Signal('');
final Computed<List<AuthCredential>> _allUsers = computed(() {
  return ([authManager.getPrimaryAuthByPlatform(_platId)] +
          authManager.getAllGuestAuthByPlatform(_platId))
      .nonNulls
      .toList();
});
final Computed<List<AuthCredential>> _filteredUsers = computed(() {
  var query = _searchQuery.value.trim().toLowerCase();
  if (query.isEmpty) return _allUsers.value;

  return _allUsers.value.where((v) {
    return v.name.toLowerCase().contains(query);
  }).toList();
});

class UserPanel extends StatefulWidget {
  final AuthCredential? currentUser;
  final void Function(AuthCredential? credential) onSelect;

  const UserPanel({
    super.key,
    required this.currentUser,
    required this.onSelect,
  });

  @override
  State<StatefulWidget> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final entries = Computed(
      () => _filteredUsers
          .watch(context)
          .map((v) {
            return FSelectTile.suffix(
              title: Row(
                spacing: 4,
                children: [
                  Text(v.name, style: const TextStyle(fontWeight: .bold)),
                  (v.guest)
                      ? null
                      : FBadge(
                          child: Text(
                            t.label.primary,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                  (v.isValid())
                      ? null
                      : FBadge(
                          variant: .destructive,
                          child: Text(
                            t.label.expired,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                ].nonNulls.toList(),
              ),
              value: v,
              enabled: v.isValid(),
            );
          })
          .nonNulls
          .toList(),
    );

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
                spacing: 8,
                children: [
                  Text(
                    t.submodule.cqupt_sport.select_user,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: .bold,
                      color: colors.foreground,
                    ),
                    maxLines: 2,
                  ),
                  Text(
                    t.submodule.cqupt_sport.select_user_hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const FDivider(),
                  FTextField(
                    control: .managed(
                      onChange: (value) => _searchQuery.value = value.text,
                    ),
                    hint: t.notice.search_user,
                  ),
                  const SizedBox(height: 8),
                  Watch((context) {
                    return FSelectTileGroup<AuthCredential>(
                      control: .managedRadio(
                        initial: widget.currentUser,
                        onChange: (v) {
                          widget.onSelect(v.first);
                        },
                      ),
                      children: entries.value,
                    );
                  }),

                  Visibility(
                    visible: entries.value.isEmpty,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: .center,
                        spacing: 8,
                        children: [
                          Icon(
                            LucideIcons.funnelX,
                            color: colors.primary,
                            size: 24,
                          ),
                          Text(
                            t.notice.no_search_result,
                            style: TextStyle(
                              color: colors.mutedForeground,
                              fontSize: 14,
                            ),
                            textAlign: .center,
                          ),
                        ],
                      ),
                    ),
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
