import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/account/code_handler.dart';
import 'package:punklorde/core/account/view/widget/info_panel.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

final Signal<String> _searchQuery = Signal('');

class GuestAccountPageView extends StatefulWidget {
  const GuestAccountPageView({super.key});

  @override
  State<StatefulWidget> createState() => _GuestAccountPageViewState();
}

class _GuestAccountPageViewState extends State<GuestAccountPageView> {
  final GlobalKey<_GuestAccountPageViewState> widgetKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final entries = (authIndexGuest.watch(context).isEmpty)
        ? null
        : currentSchoolSignal.value?.platforms.values
              .map((v) {
                final plat = authIndexGuest.watch(context)[v.id];
                if (plat == null || plat.isEmpty) {
                  return null;
                }
                final users = plat.values
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
                          ? FTile(
                              title: Text(credential.name),
                              suffix: const Icon(LucideIcons.chevronRight),
                              details: (credential.isValid())
                                  ? null
                                  : FBadge(
                                      variant: .destructive,
                                      child: Text(t.label.expired),
                                    ),
                              onPress: () {
                                showFSheet(
                                  context: context,
                                  builder: (sheetContext) =>
                                      InfoPanel(credential: credential),
                                  side: .btt,
                                );
                              },
                            )
                          : null;
                    })
                    .nonNulls
                    .toList();
                return (users.isNotEmpty)
                    ? FTileGroup(label: Text(v.name), children: users)
                    : null;
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
              title: Text(t.setting.guest_account),
              prefixes: [
                FHeaderAction.back(
                  onPress: () {
                    context.pop();
                  },
                ),
              ],
              suffixes: [
                FHeaderAction(
                  icon: const Icon(LucideIcons.userRoundPlus),
                  onPress: () {
                    context.push('/p/scan').then((v) async {
                      final context = widgetKey.currentContext;
                      if (v == null) return;
                      if (handlerGuestAccount.match(v) &&
                          context != null &&
                          context.mounted) {
                        await handlerGuestAccount.handle(context, v);
                      } else {
                        if (context != null && context.mounted) {
                          toastification.show(
                            context: context,
                            title: Text(t.notice.invalid_qr_code),
                            autoCloseDuration: const Duration(seconds: 3),
                            animationDuration: const Duration(
                              milliseconds: 300,
                            ),
                            primaryColor: Colors.red,
                            icon: const Icon(LucideIcons.circleX),
                          );
                        }
                      }
                    });
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
