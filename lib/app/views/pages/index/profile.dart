import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          spacing: 8,
          children: [
            Padding(
              padding: .fromLTRB(16, 8, 16, 8),
              child: FTileGroup(
                label: const Text('设置'),
                children: [
                  FTile(
                    title: const Text("账号管理"),
                    suffix: Icon(LucideIcons.chevronRight),
                    onPress: () {
                      context.push('/p/account');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
