import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/account/view/widget/info_panel.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

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

class PrimaryAccountPageView extends StatefulWidget {
  const PrimaryAccountPageView({super.key});

  @override
  State<StatefulWidget> createState() => _PrimaryAccountPageViewState();
}

class _PrimaryAccountPageViewState extends State<PrimaryAccountPageView> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final entries = _filteredPlats.watch(context)?.map((v) {
      final guid = authIndexPrimary.watch(context)[v.id];
      late final AuthCredential? credential;
      if (guid == null) {
        credential = null;
      } else {
        credential = authCredentials.watch(context)[guid];
      }
      return FTile(
        title: Text(v.name),
        suffix: (credential != null)
            ? ((credential.isValid())
                  ? const Icon(LucideIcons.circleCheck, color: Colors.green)
                  : FBadge(variant: .destructive, child: Text(t.label.expired)))
            : null,
        subtitle: (credential != null)
            ? Row(
                spacing: 2,
                children: [
                  Text(t.notice.logged_in),
                  Text(
                    credential.name,
                    style: TextStyle(color: colors.primary, fontWeight: .bold),
                  ),
                ],
              )
            : Text(t.notice.not_login),
        onPress: () async {
          if (credential == null) {
            final newCredential = await v.login(context);
            if (newCredential != null) {
              setAuthCredential(newCredential);
            }
            if (context.mounted) {
              toastification.show(
                context: context,
                title: (newCredential != null)
                    ? Text(t.notice.login_success)
                    : Text(t.notice.login_failed),
                description: Text(v.name),
                autoCloseDuration: const Duration(seconds: 3),
                primaryColor: (newCredential != null)
                    ? Colors.green
                    : Colors.red,
                icon: (newCredential != null)
                    ? const Icon(LucideIcons.circleCheck)
                    : const Icon(LucideIcons.circleX),
              );
            }
          } else {
            showFSheet(
              context: context,
              builder: (sheetContext) => InfoPanel(credential: credential!),
              side: .btt,
            );
          }
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
              title: Text(t.setting.primary_account),
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
