import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/module/feature/vpn/sangfor/data.dart';
import 'package:signals/signals_flutter.dart';

class VpnTrafficWidget extends StatelessWidget {
  const VpnTrafficWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final stats = vpnTraffic.watch(context);

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(LucideIcons.activity, size: 16, color: colors.mutedForeground),
                Text(
                  'Traffic',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildStat(context, 'Sent', stats.sentFormatted, LucideIcons.arrowUp, colors.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildStat(context, 'Received', stats.receivedFormatted, LucideIcons.arrowDown, colors.secondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colors = context.theme.colors;
    return Row(
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.mutedForeground,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}