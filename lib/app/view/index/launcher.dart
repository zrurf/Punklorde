import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:punklorde/core/status/app.dart';

class LauncherView extends StatefulWidget {
  const LauncherView({super.key});

  @override
  State<LauncherView> createState() => _LauncherViewState();
}

class _LauncherViewState extends State<LauncherView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        if (currentSchoolSignal.value == null) {
          context.go('/p/select_school');
        } else {
          context.go('/index/home');
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
