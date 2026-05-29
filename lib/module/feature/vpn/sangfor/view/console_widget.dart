import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/module/feature/vpn/sangfor/data.dart';
import 'package:signals/signals_flutter.dart';

class VpnConsoleWidget extends StatelessWidget {
  const VpnConsoleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final logs = vpnLogs.watch(context);

    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(Icons.terminal, size: 16, color: colors.mutedForeground),
                Text(
                  'Console',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} lines',
                  style: TextStyle(fontSize: 11, color: colors.mutedForeground),
                ),
              ],
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.mutedForeground.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  key: ValueKey('vpn_console_${logs.length}'),
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    final color = switch (entry.level) {
                      VpnLogLevel.info => colors.mutedForeground,
                      VpnLogLevel.success => colors.primary,
                      VpnLogLevel.warning => colors.secondary,
                      VpnLogLevel.error => colors.destructive,
                    };
                    final time =
                        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                        '${entry.timestamp.second.toString().padLeft(2, '0')}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$time ',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.mutedForeground.withValues(
                                  alpha: 0.5,
                                ),
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: '[${entry.levelLabel}] ',
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: entry.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.foreground.withValues(alpha: 0.8),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
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
