import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/common/models/auth.dart';
import 'package:punklorde/common/models/school.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:xxh3/xxh3.dart';

class AuthManager {
  final Map<String, AccountProvider> _providers = {};

  AuthManager();

  void registerProvider(AccountProvider provider) {
    _providers[provider.id] = provider;
  }

  void initWithSchool(SchoolModel school) {
    for (final provider in school.accountProviders) {
      registerProvider(provider);
    }

    refreshAll();
  }

  Future<bool> login(BuildContext context, String providerId) async {
    if (_providers[providerId] == null) {
      toastification.show(
        context: context,
        title: const Text("登录失败"),
        description: const Text("找不到对应的登录方式"),
        autoCloseDuration: const Duration(seconds: 3),
        primaryColor: Colors.red,
        icon: Icon(LucideIcons.circleX),
      );
      return false;
    }
    var prov = _providers[providerId]!;
    Map<String, dynamic> param = {};

    if (!prov.reqireUi) {
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
                    "登录到 ${prov.name}",
                    style: TextStyle(fontWeight: .bold, fontSize: 20),
                  ),
                  Column(
                    spacing: 8,
                    children: prov.inputSchema!
                        .map<Widget>(
                          (item) => FTextField(
                            label: Text(item.lable),
                            hint: item.hint,
                            description: (item.desc == null)
                                ? null
                                : Text(item.desc!),
                            obscureText: item.hidden,
                            control: FTextFieldControl.managed(
                              onChange: (value) {
                                param[item.id] = value.text;
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  FButton(
                    onPress: () async {
                      var auth = await prov.login(context, param);
                      if (auth != null) {
                        authCredential.value[providerId] = auth;
                      }
                      if (auth != null && ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (context.mounted) {
                        toastification.show(
                          context: context,
                          title: (auth != null)
                              ? const Text("登录成功")
                              : const Text("登录失败"),
                          description: Text(
                            "${prov.name} 登录${(auth != null) ? "成功" : "失败"}",
                          ),
                          autoCloseDuration: const Duration(seconds: 3),
                          primaryColor: (auth != null)
                              ? Colors.green
                              : Colors.red,
                          icon: (auth != null)
                              ? Icon(LucideIcons.circleCheck)
                              : Icon(LucideIcons.circleX),
                        );
                      }
                    },
                    child: Text("登录"),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {}

    return false;
  }

  Future<bool> logout(AuthCredential auth) async {
    if (!_providers.containsKey(auth.type)) {
      return false;
    }
    bool res = await _providers[auth.type]?.logout(auth) ?? true;
    authCredential.value.remove(auth.type);
    return res;
  }

  Future<bool> guestLogin(BuildContext context) async {
    String shareCode = "";
    String guestName = "";

    WoltModalSheet.show(
      context: context,
      pageListBuilder: (ctx) => [
        WoltModalSheetPage(
          child: Padding(
            padding: .fromLTRB(16, 2, 16, 8),
            child: Column(
              spacing: 8,
              children: [
                Text("访客登录", style: TextStyle(fontWeight: .bold, fontSize: 20)),
                FTextField(
                  label: const Text("访客名称"),
                  hint: "请输入访客名称",
                  control: FTextFieldControl.managed(
                    onChange: (value) {
                      guestName = value.text;
                    },
                  ),
                ),
                FTextField.multiline(
                  label: const Text("分享码"),
                  hint: "分享码应该以 eyJ 开头...",
                  description: Text("请输入访客的分享码"),
                  control: FTextFieldControl.managed(
                    onChange: (value) {
                      shareCode = value.text;
                    },
                  ),
                ),
                FButton(
                  onPress: () {
                    if (shareCode.isEmpty || guestName.isEmpty) {
                      toastification.show(
                        context: context,
                        title: const Text("登录失败"),
                        description: const Text("请填写完整的信息"),
                        autoCloseDuration: const Duration(seconds: 3),
                        primaryColor: Colors.red,
                        icon: Icon(LucideIcons.circleX),
                      );
                      return;
                    }
                    AuthCredential credential;
                    try {
                      credential = AuthCredential.fromJson(
                        jsonDecode(utf8.decode(base64.decode(shareCode))),
                      );
                    } catch (e) {
                      toastification.show(
                        context: context,
                        title: const Text("登录失败"),
                        description: const Text("无法解析分享码，分享码格式错误"),
                        autoCloseDuration: const Duration(seconds: 3),
                        primaryColor: Colors.red,
                        icon: Icon(LucideIcons.circleX),
                      );
                      return;
                    }

                    if (!_providers.containsKey(credential.type)) {
                      toastification.show(
                        context: context,
                        title: const Text("登录失败"),
                        description: const Text("没有分享码匹配的平台"),
                        autoCloseDuration: const Duration(seconds: 3),
                        primaryColor: Colors.red,
                        icon: Icon(LucideIcons.circleX),
                      );
                      return;
                    }

                    String aid = xxh3String(utf8.encode(guestName));

                    if (guestAuthCredential.value[credential.type]?.containsKey(
                          aid,
                        ) ??
                        false) {
                      toastification.show(
                        context: context,
                        title: const Text("登录失败"),
                        description: const Text("访客名称已存在"),
                        autoCloseDuration: const Duration(seconds: 3),
                        primaryColor: Colors.red,
                        icon: Icon(LucideIcons.circleX),
                      );
                      return;
                    }

                    var prov = _providers[credential.type]!;

                    if (guestAuthCredential.value[credential.type] == null) {
                      guestAuthCredential.value[credential.type] = {};
                    }

                    guestAuthCredential.value[credential.type]![aid] =
                        GuestAuthCredential(
                          id: aid,
                          name: guestName,
                          auth: credential,
                        );

                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      toastification.show(
                        context: context,
                        title: const Text("访客登录成功"),
                        description: Text("${prov.name} 访客登录成功"),
                        autoCloseDuration: const Duration(seconds: 3),
                        primaryColor: Colors.green,
                        icon: Icon(LucideIcons.circleCheck),
                      );
                    }
                  },
                  child: Text("登录"),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return true;
  }

  void guestLogout(GuestAuthCredential auth) {
    guestAuthCredential.value[auth.auth.type]?.remove(auth.id);
  }

  Future<void> refreshAll() async {
    final newMap = Map<String, AuthCredential>.from(authCredential.value);

    for (final entry in authCredential.value.entries) {
      final idx = entry.key;
      final auth = entry.value;

      if (_providers.containsKey(auth.type) &&
          _providers[auth.type]!.supportRefresh) {
        final refreshed = await _providers[auth.type]?.refresh(auth);
        if (refreshed != null) {
          newMap[idx] = refreshed;
        }
      }
    }

    authCredential.value = newMap;
  }

  Future<bool> refreshAuth(String id) async {
    if (!authCredential.containsKey(id)) {
      return false;
    }
    final auth = authCredential.value[id]!;
    if (_providers.containsKey(auth.type) &&
        _providers[auth.type]!.supportRefresh) {
      final refreshed = await _providers[auth.type]?.refresh(auth);
      if (refreshed != null) {
        authCredential.value[id] = refreshed;
        return true;
      }
    }
    return false;
  }

  AuthCredential? getAuth(String id) {
    return authCredential.value[id];
  }

  List<GuestAuthCredential> getGuestAuths(String id) {
    return (guestAuthCredential.value[id] ?? {}).values.toList();
  }

  GuestAuthCredential? getGuestAuth(String pid, String aid) {
    return (guestAuthCredential.value[pid] ?? {})[aid];
  }

  AccountProvider? getProvider(String id) {
    return _providers[id];
  }
}
