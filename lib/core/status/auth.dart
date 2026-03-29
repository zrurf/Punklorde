import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:punklorde/core/account/manager.dart';
import 'package:punklorde/core/account/utils.dart';
import 'package:punklorde/core/status/checkin.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:signals/signals.dart';

// 认证状态
final Signal<BuiltMap<String, AuthCredential>> authCredentials = signal(
  BuiltMap({}),
);

// 索引
final Signal<BuiltMap<String, String>> authIndexPrimary = signal(
  BuiltMap({}),
); // 主用户索引

final Signal<BuiltMap<String, Map<String, String>>> authIndexGuest = signal(
  BuiltMap({}),
); // 访客用户索引

// 认证管理器
final AuthManager authManager = AuthManager();

// 设置认证凭证
void setAuthCredential(AuthCredential credential) {
  final guid = genAuthCredentialGuid(credential);
  authCredentials.value = authCredentials.value.rebuild(
    (b) => b[guid] = credential,
  );
  // 更新索引
  if (credential.guest) {
    if (authIndexGuest.value.containsKey(credential.type)) {
      authIndexGuest.value = authIndexGuest.value.rebuild(
        (b) => b[credential.type]![credential.id] = guid,
      );
    } else {
      authIndexGuest.value = authIndexGuest.value.rebuild(
        (b) => b[credential.type] = {credential.id: guid},
      );
    }
  } else {
    authIndexPrimary.value = authIndexPrimary.value.rebuild(
      (b) => b[credential.type] = guid,
    );
  }
}

// 移除认证凭证
void removeAuthCredentialById(String guid) {
  final credential = authCredentials.value[guid];
  if (credential == null) return;
  removeAuthCredentialByCredential(credential);
}

// 通过凭证移除认证凭证
void removeAuthCredentialByCredential(AuthCredential credential) {
  final guid = genAuthCredentialGuid(credential);
  authCredentials.value = authCredentials.value.rebuild((b) => b.remove(guid));
  removeAuthStore(guid);
  // 更新索引
  if (credential.guest) {
    authIndexGuest.value = authIndexGuest.value.rebuild((b) {
      b[credential.type]?.remove(credential.id);
      if (b[credential.type]?.isEmpty ?? false) {
        b.remove(credential.type);
      }
    });
  } else {
    authIndexPrimary.value = authIndexPrimary.value.rebuild(
      (b) => b.remove(credential.type),
    );
  }
}

// 通过平台ID移除主用户认证凭证
void removePrimaryAuthCredentialByPlatform(String platformId) {
  final guid = authIndexPrimary.value[platformId];
  if (guid == null) return;
  removeAuthCredentialById(guid);
}

// 获取主用户认证凭证
AuthCredential? getPrimaryAuthCredentialByPlatform(String platformId) {
  final guid = authIndexPrimary.value[platformId];
  if (guid == null) return null;
  return authCredentials.value[guid];
}

// 获取访客用户认证凭证
AuthCredential? getGuestAuthCredentialById(String platformId, String id) {
  final guid = authIndexGuest.value[platformId]?[id];
  if (guid == null) return null;
  return authCredentials.value[guid];
}

// 通过平台获取所有访客用户认证凭证
List<AuthCredential> getAllGuestAuthCredentialByPlatform(String platformId) {
  final guids = authIndexGuest.value[platformId]?.values ?? [];
  return guids.map((guid) => authCredentials.value[guid]).nonNulls.toList();
}

// 获取所有访客用户认证凭证
List<AuthCredential> getAllGuestAuthCredential() {
  return authCredentials.value.values.where((v) => v.guest).toList();
}

// 获取所有访客用户认证凭证
List<AuthCredential> getAllPrimaryAuthCredential() {
  return authCredentials.value.values.where((v) => !v.guest).toList();
}

// 重建索引
void rebuildIndex() {
  authIndexPrimary.value = authIndexPrimary.value.rebuild((b) => b.clear());
  authIndexGuest.value = authIndexGuest.value.rebuild((b) => b.clear());
  authCredentials.value.forEach((k, v) {
    if (v.guest) {
      if (authIndexGuest.value.containsKey(v.type)) {
        authIndexGuest.value = authIndexGuest.value.rebuild(
          (b) => b[v.type]![v.id] = k,
        );
      } else {
        authIndexGuest.value = authIndexGuest.value.rebuild(
          (b) => b[v.type] = {v.id: k},
        );
      }
    } else {
      authIndexPrimary.value = authIndexPrimary.value.rebuild(
        (b) => b[v.type] = k,
      );
    }
  });
}

// 初始化认证状态
void initAuthStatus() {
  effect(() {
    storeAuthStatus();
  });
  initCheckinAuth(
    authCredentials.value.values
        .map((v) => (v.guest) ? null : v)
        .nonNulls
        .toList(),
  );
}

// 存储认证状态
Future<void> storeAuthStatus() async {
  final storage = StorageService();
  await storage.putList(
    '_c_keys',
    authCredentials.value.asMap().keys.toList(),
    instance: authMMKV,
  );
  authCredentials.value.asMap().forEach((k, v) async {
    await storage.putBytes(
      'c_$k',
      Uint8List.fromList(v.toCbor()),
      instance: authMMKV,
    );
  });
}

Future<void> removeAuthStore(String id) async {
  final storage = StorageService();
  storage.remove('c_$id');
}

// 加载认证状态
Future<void> loadAuthStatus() async {
  final storage = StorageService();

  final keys = (await storage.getList(
    '_c_keys',
    instance: authMMKV,
  ))?.cast<String>();

  if (keys == null) return;

  for (final key in keys) {
    final data = (await storage.getBytes(
      'c_$key',
      instance: authMMKV,
    ))?.toList();
    if (data == null) continue;
    final credential = AuthCredential.fromCbor(data);
    setAuthCredential(credential);
  }

  rebuildIndex();
}
