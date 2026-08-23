import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// 兼容 forui 0.24+ 的对话框内容布局。
Widget punklordeDialog({
  required FDialogStyleDelta style,
  Animation<double>? animation,
  Widget? image,
  Widget? title,
  Widget? body,
  List<Widget> actions = const [],
}) {
  return FDialog(
    style: style,
    animation: animation,
    builder: (context, style) {
      final content = <Widget>[
        if (image != null) ...[
          image,
          if (title != null || body != null) const SizedBox(height: 9),
        ],
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DefaultTextStyle(
              style: style.titleTextStyle,
              child: Center(child: title),
            ),
          ),
          if (body != null) const SizedBox(height: 9),
        ],
        if (body != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DefaultTextStyle(style: style.bodyTextStyle, child: body),
          ),
        if ((image != null || title != null || body != null) &&
            actions.isNotEmpty)
          const SizedBox(height: 20),
        if (actions.isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: action,
                ),
            ],
          ),
      ];
      return Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 18,
          bottom: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      );
    },
  );
}
