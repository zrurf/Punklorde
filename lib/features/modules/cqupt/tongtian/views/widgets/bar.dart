import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class RunningStatusBar extends StatefulWidget {
  const RunningStatusBar({super.key});

  @override
  State<RunningStatusBar> createState() => _RunningStatusBarState();
}

class _RunningStatusBarState extends State<RunningStatusBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 30,
            child: Column(children: [Text("123")]),
          ),
        ],
      ),
    );
  }
}
