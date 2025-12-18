import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FButton(
          onPress: () => context.push('/mod/tongtian'),
          child: Text("校园跑"),
        ),
      ],
    );
  }
}
