import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';

class VpnConfigSection extends StatefulWidget {
  final TextEditingController serverController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController totpSecretController;
  final TextEditingController dnsController;

  const VpnConfigSection({
    super.key,
    required this.serverController,
    required this.usernameController,
    required this.passwordController,
    required this.totpSecretController,
    required this.dnsController,
  });

  @override
  State<VpnConfigSection> createState() => _VpnConfigSectionState();
}

class _VpnConfigSectionState extends State<VpnConfigSection> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          t.submodule.sangfor_vpn.configuration,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),

        // Server
        _buildField(
          label: Text(t.submodule.sangfor_vpn.server),
          hint: t.submodule.sangfor_vpn.server_hint,
          icon: LucideIcons.server,
          controller: widget.serverController,
          keyboardType: TextInputType.url,
        ),

        // Username
        _buildField(
          label: Text(t.submodule.sangfor_vpn.username),
          icon: LucideIcons.user,
          controller: widget.usernameController,
        ),

        // Password
        FTextField.password(
          control: .managed(controller: widget.passwordController),
          label: Text(t.submodule.sangfor_vpn.password),
          hint: t.submodule.sangfor_vpn.password,
        ),

        // Advanced toggle
        FButton(
          variant: .ghost,
          size: .sm,
          onPress: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            spacing: 4,
            children: [
              Icon(
                _showAdvanced ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
              ),
              Text(t.submodule.sangfor_vpn.advanced_settings),
            ],
          ),
        ),

        // Advanced fields
        if (_showAdvanced) ...[
          _buildField(
            label: Text(t.submodule.sangfor_vpn.totp_secret),
            hint: t.submodule.sangfor_vpn.totp_secret_hint,
            icon: LucideIcons.keyRound,
            controller: widget.totpSecretController,
          ),
          _buildField(
            label: Text(t.submodule.sangfor_vpn.custom_dns),
            hint: t.submodule.sangfor_vpn.custom_dns_hint,
            icon: LucideIcons.globe,
            controller: widget.dnsController,
            keyboardType: TextInputType.url,
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required Widget label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return FTextField(
      control: .managed(controller: controller),
      label: label,
      hint: hint,
      keyboardType: keyboardType,
      prefixBuilder: (context, style, variants) =>
          FTextField.prefixIconBuilder(context, style, variants, Icon(icon, size: 18)),
    );
  }
}