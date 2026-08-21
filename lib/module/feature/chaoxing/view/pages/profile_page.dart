import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/chaoxing/chaoxing.dart';
import 'package:punklorde/utils/etc/time.dart';
import 'package:signals/signals_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final credential = authCredentials.watch(
      context,
    )[authIndexPrimary.watch(context)[platChaoxing.id]];

    if (credential == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 36,
              color: colors.destructive.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              t.notice.not_login,
              style: TextStyle(color: colors.destructive, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          _buildUserCard(context, credential),
          const SizedBox(height: 12),
          _buildInfoGroup(context, credential),
          const SizedBox(height: 12),
          _buildSettingsGroup(context),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthCredential cred) {
    final colors = context.theme.colors;
    final avatar = cred.ext?['avatar'] as String?;
    final phone = cred.ext?['phone'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: (avatar != null && avatar.isNotEmpty)
                ? Image.network(
                    avatar,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => _avatarPlaceholder(colors),
                  )
                : _avatarPlaceholder(colors),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cred.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cred.isValid()
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.destructive.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              cred.isValid() ? t.notice.logged_in : t.label.expired,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: cred.isValid() ? colors.primary : colors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(FColors colors) {
    return Container(
      color: colors.primary.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Icon(LucideIcons.userRound, size: 24, color: colors.primary),
    );
  }

  Widget _buildInfoGroup(BuildContext context, AuthCredential cred) {
    final phone = cred.ext?['phone'] as String?;
    final deviceId = cred.ext?['device_id'] as String?;
    final ua = cred.ext?['ua'] as String?;

    return FTileGroup(
      children: [
        FTile(title: Text(t.title.id), subtitle: Text(cred.id)),
        if (phone != null && phone.isNotEmpty)
          FTile(title: Text(t.title.phone_num), subtitle: Text(phone)),
        FTile(
          title: Text(t.title.exprire_at),
          subtitle: Text(formatDate(cred.expireAt)),
        ),
        if (deviceId != null)
          FTile(title: const Text('Device ID'), subtitle: Text(deviceId)),
        if (ua != null)
          FTile(
            title: const Text('User-Agent'),
            subtitle: Text(_truncateUA(ua)),
          ),
      ],
    );
  }

  Widget _buildSettingsGroup(BuildContext context) {
    final colors = context.theme.colors;
    return FTileGroup(
      children: [
        FTile(
          title: Text(t.submodule.chaoxing.mods),
          prefix: Icon(LucideIcons.box, color: colors.primary),
          suffix: const Icon(LucideIcons.chevronRight),
          onPress: () {},
        ),
        FTile(
          title: Text(t.common.setting),
          prefix: Icon(LucideIcons.cog, color: colors.primary),
          suffix: const Icon(LucideIcons.chevronRight),
          onPress: () {},
        ),
      ],
    );
  }

  String _truncateUA(String ua) {
    if (ua.length <= 40) return ua;
    return '${ua.substring(0, 40)}...';
  }
}
