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
    }

    return true;
  }

  Future<bool> logout(AuthCredential auth) async {
    if (!_providers.containsKey(auth.type)) {
      return false;
    }
    bool res = await _providers[auth.type]?.logout(auth) ?? true;
    authCredential.value.remove(auth.type);
    return res;
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

  AccountProvider? getProvider(String id) {
    return _providers[id];
  }
}
