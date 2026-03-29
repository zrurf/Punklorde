import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/model/code_handler.dart';

class ScannerOpenPanel extends StatefulWidget {
  final List<CodeHandler> handlers;
  final dynamic data;
  final void Function() onClose;

  const ScannerOpenPanel({
    super.key,
    required this.handlers,
    required this.data,
    required this.onClose,
  });

  @override
  State<StatefulWidget> createState() => _ScannerOpenPanelState();
}

class _ScannerOpenPanelState extends State<ScannerOpenPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
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
                constraints: BoxConstraints(maxWidth: 450),
                child: Column(
                  spacing: 8,
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      t.action.open_with,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: .bold,
                        color: colors.foreground,
                      ),
                      maxLines: 2,
                    ),
                    Text(
                      t.notice.open_code_hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const FDivider(),
                    Column(
                      spacing: 8,
                      children: widget.handlers
                          .map<Widget>(
                            (item) => FTile(
                              title: Text(item.name),
                              suffix: Icon(
                                LucideIcons.arrowRight,
                                color: colors.primary,
                              ),
                              onPress: () {
                                item.handle(context, widget.data);
                                Navigator.of(context).pop();
                                widget.onClose();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
