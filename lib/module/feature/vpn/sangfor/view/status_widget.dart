import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/vpn/sangfor/data.dart';

class VpnStatusWidget extends StatelessWidget {
  final VpnConnectionState state;
  final String? message;
  final bool isRunning;

  const VpnStatusWidget({
    super.key,
    required this.state,
    this.message,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (icon, title, subtitle, color) = _getStatusInfo(colors);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        spacing: 12,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 32, color: color),
          ),

          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),

          if (subtitle != null)
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
            ),

          if (message != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message!,
                style: TextStyle(fontSize: 12, color: colors.destructive),
              ),
            ),

          if (isRunning && state != VpnConnectionState.connected)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
        ],
      ),
    );
  }

  (IconData, String, String?, Color) _getStatusInfo(FColors colors) {
    return switch (state) {
      VpnConnectionState.disconnected => (
        LucideIcons.shieldOff,
        t.submodule.sangfor_vpn.status_disconnected,
        t.submodule.sangfor_vpn.status_not_connected,
        colors.mutedForeground,
      ),
      VpnConnectionState.connecting => (
        LucideIcons.plug,
        t.submodule.sangfor_vpn.status_connecting,
        t.submodule.sangfor_vpn.status_establishing,
        colors.secondary,
      ),
      VpnConnectionState.loginStart => (
        LucideIcons.logIn,
        t.submodule.sangfor_vpn.status_authenticating,
        t.submodule.sangfor_vpn.status_login_session,
        colors.secondary,
      ),
      VpnConnectionState.loginPassword => (
        LucideIcons.lock,
        t.submodule.sangfor_vpn.status_verifying,
        t.submodule.sangfor_vpn.status_submitting,
        colors.secondary,
      ),
      VpnConnectionState.waitingSms => (
        LucideIcons.messageSquare,
        t.submodule.sangfor_vpn.status_sms_required,
        t.submodule.sangfor_vpn.status_sms_hint,
        colors.secondary,
      ),
      VpnConnectionState.waitingTotp => (
        LucideIcons.keyRound,
        t.submodule.sangfor_vpn.status_totp_required,
        t.submodule.sangfor_vpn.status_totp_hint,
        colors.secondary,
      ),
      VpnConnectionState.gettingToken => (
        LucideIcons.fingerprint,
        t.submodule.sangfor_vpn.status_getting_token,
        t.submodule.sangfor_vpn.status_exchanging,
        colors.secondary,
      ),
      VpnConnectionState.gettingResources => (
        LucideIcons.list,
        t.submodule.sangfor_vpn.status_fetching,
        t.submodule.sangfor_vpn.status_retrieving,
        colors.secondary,
      ),
      VpnConnectionState.gettingIp => (
        LucideIcons.network,
        t.submodule.sangfor_vpn.status_assigning_ip,
        t.submodule.sangfor_vpn.status_requesting_ip,
        colors.secondary,
      ),
      VpnConnectionState.openingChannels => (
        LucideIcons.orbit,
        t.submodule.sangfor_vpn.status_opening,
        t.submodule.sangfor_vpn.status_channels,
        colors.secondary,
      ),
      VpnConnectionState.connected => (
        LucideIcons.shieldCheck,
        t.submodule.sangfor_vpn.status_connected,
        t.submodule.sangfor_vpn.status_tunnel_active,
        colors.primary,
      ),
      VpnConnectionState.error => (
        LucideIcons.triangleAlert,
        t.submodule.sangfor_vpn.status_failed,
        t.submodule.sangfor_vpn.status_error_occurred,
        colors.destructive,
      ),
    };
  }
}
