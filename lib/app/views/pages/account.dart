import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/school.dart';
import 'package:signals/signals_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<StatefulWidget> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FHeader.nested(
            title: Text("账号管理"),
            prefixes: [
              FHeaderAction.back(
                onPress: () {
                  context.pop();
                },
              ),
            ],
            suffixes: [
              FHeaderAction(
                icon: Icon(LucideIcons.userRoundPlus),
                onPress: () {
                  authManager.guestLogin(context);
                },
              ),
            ],
          ),
          Padding(
            padding: .fromLTRB(16, 2, 16, 8),
            child: Column(
              spacing: 8,
              children: [
                const Text(
                  "主账号",
                  textAlign: .left,
                  style: TextStyle(fontWeight: .bold, fontSize: 18),
                ),
                Column(
                  spacing: 8,
                  children:
                      currentSchool.watch(context)?.accountProviders.map<
                        Widget
                      >((p) {
                        return FTile(
                          title: Text(p.name),
                          prefix:
                              (authCredential.watch(context).containsKey(p.id))
                              ? Icon(
                                  LucideIcons.circleCheck,
                                  color: Colors.green,
                                )
                              : Icon(
                                  LucideIcons.circleMinus,
                                  color: Colors.grey,
                                ),
                          suffix: Icon(LucideIcons.chevronRight),
                          onPress: () {
                            if (authCredential
                                .watch(context)
                                .containsKey(p.id)) {
                              var authCred = authCredential.watch(
                                context,
                              )[p.id]!;
                              WoltModalSheet.show(
                                context: context,
                                pageListBuilder: (ctx) => [
                                  WoltModalSheetPage(
                                    child: Padding(
                                      padding: .fromLTRB(16, 2, 16, 8),
                                      child: Column(
                                        spacing: 8,
                                        children: [
                                          Text(
                                            "已经登录到 ${authManager.getProvider(authCred.type)?.name}",
                                            style: TextStyle(
                                              fontWeight: .bold,
                                              fontSize: 20,
                                            ),
                                          ),

                                          FItem(
                                            title: Text("查看登录信息"),
                                            prefix: Icon(LucideIcons.fileUser),
                                            suffix: Icon(
                                              LucideIcons.chevronRight,
                                            ),
                                            onPress: () {
                                              showFDialog(
                                                context: context,
                                                builder: (context, style, animation) => FDialog(
                                                  style: style,
                                                  animation: animation,
                                                  direction: Axis.horizontal,
                                                  constraints: BoxConstraints(
                                                    maxHeight: 280,
                                                  ),
                                                  title: const Text("登录信息"),
                                                  body: Column(
                                                    children: [
                                                      Text(
                                                        "分享码：",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: .bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        base64.encode(
                                                          utf8.encode(
                                                            jsonEncode(
                                                              authCred.toJson(),
                                                            ),
                                                          ),
                                                        ),
                                                        maxLines: 5,
                                                        overflow: .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    FButton(
                                                      style:
                                                          FButtonStyle.outline(),
                                                      onPress: () {
                                                        Clipboard.setData(
                                                          ClipboardData(
                                                            text: base64.encode(
                                                              utf8.encode(
                                                                jsonEncode(
                                                                  authCred
                                                                      .toJson(),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      child: const Text(
                                                        '复制分享码',
                                                      ),
                                                    ),
                                                    FButton(
                                                      style:
                                                          FButtonStyle.primary(),
                                                      onPress: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                      child: const Text('确定'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          FItem(
                                            title: Text(
                                              "退出登录",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            prefix: Icon(LucideIcons.logOut),
                                            onPress: () {
                                              authManager.logout(authCred);
                                              Navigator.of(ctx).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              authManager.login(context, p.id);
                            }
                          },
                          onLongPress: () {},
                        );
                      }).toList() ??
                      [],
                ),
                FDivider(),
                const Text(
                  "访客账号",
                  textAlign: .left,
                  style: TextStyle(fontWeight: .bold, fontSize: 18),
                ),
                Column(
                  spacing: 8,
                  children: guestAuthCredential.watch(context).keys.map<Widget>(
                    (pid) {
                      return FTileGroup(
                        label: Text(
                          authManager.getProvider(pid)?.name ?? "未知平台",
                        ),
                        description: const Text("显示已登录的访客"),
                        children:
                            (guestAuthCredential
                                        .watch(context)[pid]
                                        ?.values
                                        .map<FTile>(
                                          (v) => FTile(
                                            title: Text(v.name),
                                            prefix: Icon(LucideIcons.user),
                                            suffix: Icon(
                                              LucideIcons.chevronRight,
                                            ),
                                            onPress: () {
                                              WoltModalSheet.show(
                                                context: context,
                                                pageListBuilder: (ctx) => [
                                                  WoltModalSheetPage(
                                                    child: Padding(
                                                      padding: .fromLTRB(
                                                        16,
                                                        2,
                                                        16,
                                                        8,
                                                      ),
                                                      child: Column(
                                                        spacing: 8,
                                                        children: [
                                                          Text(
                                                            "访客 ${v.name}",
                                                            style: TextStyle(
                                                              fontWeight: .bold,
                                                              fontSize: 20,
                                                            ),
                                                          ),
                                                          FItem(
                                                            title: Text(
                                                              "退出登录",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                            prefix: Icon(
                                                              LucideIcons
                                                                  .logOut,
                                                            ),
                                                            onPress: () {
                                                              authManager
                                                                  .guestLogout(
                                                                    v,
                                                                  );
                                                              Navigator.of(
                                                                ctx,
                                                              ).pop();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                            onLongPress: () {},
                                          ),
                                        ) ??
                                    [])
                                .toList(),
                      );
                    },
                  ).toList(),
                ),
                Text(
                  "没有更多了",
                  textAlign: .center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
