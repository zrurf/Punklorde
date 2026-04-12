import 'package:dart_date/dart_date.dart';
import 'package:punklorde/core/account/utils.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/model/auth.dart';

class AuthManager {
  // 注销
  Future<bool> logout(String platformId) async {
    final credential = getPrimaryAuthCredentialByPlatform(platformId);
    if (credential == null) {
      return false;
    }
    logoutByCredential(credential);
    return true;
  }

  // 注销
  Future<bool> logoutByCredential(AuthCredential credential) async {
    removeAuthCredentialByCredential(credential);
    await currentSchoolSignal.value?.platforms[credential.type]?.logout(
      credential,
    );
    return true;
  }

  // 刷新主账号
  Future<bool> refreshPrimary(String platformId) async {
    final credential = getPrimaryAuthCredentialByPlatform(platformId);
    if (credential == null) {
      return false;
    }
    final refreshResult = await currentSchoolSignal.value?.platforms[platformId]
        ?.refresh(credential);
    if (refreshResult == null) {
      return false;
    }
    setAuthCredential(refreshResult.copyWith(guest: false));
    return true;
  }

  // 刷新访客
  Future<bool> refreshGuest(String platformId, String id) async {
    final credential = getGuestAuthCredentialById(platformId, id);
    if (credential == null) {
      return false;
    }
    final refreshResult = await currentSchoolSignal.value?.platforms[platformId]
        ?.refresh(credential);
    if (refreshResult == null) {
      return false;
    }
    setAuthCredential(refreshResult.copyWith(guest: true));
    return true;
  }

  // 刷新平台下所有访客
  Future<bool> refreshAllGuest(String platformId) async {
    final credentials = getAllGuestAuthCredentialByPlatform(platformId);
    if (credentials.isEmpty) {
      return false;
    }
    bool result = true;
    for (final credential in credentials) {
      final refreshResult = await currentSchoolSignal
          .value
          ?.platforms[platformId]
          ?.refresh(credential);
      if (refreshResult == null) {
        result = false;
      } else {
        setAuthCredential(refreshResult.copyWith(guest: true));
      }
    }
    return result;
  }

  // 刷新凭据
  Future<bool> refreshByCredential(AuthCredential credential) async {
    return (await refreshAndGetByCredential(credential)) != null;
  }

  // 刷新凭据并获取
  Future<AuthCredential?> refreshAndGetByCredential(
    AuthCredential credential,
  ) async {
    final refreshResult = await currentSchoolSignal
        .value
        ?.platforms[credential.type]
        ?.refresh(credential);
    if (refreshResult == null) {
      return null;
    }
    final newCredential = refreshResult.copyWith(guest: credential.guest);
    setAuthCredential(newCredential);
    return newCredential;
  }

  // 刷新所有凭据
  Future<bool> refreshAll() async {
    bool result = true;
    for (final credential in authCredentials.value.values) {
      final refreshResult = await currentSchoolSignal
          .value
          ?.platforms[credential.type]
          ?.refresh(credential);
      if (refreshResult == null) {
        result = false;
      } else {
        setAuthCredential(refreshResult.copyWith(guest: credential.guest));
      }
    }
    return result;
  }

  // 刷新所有已过期的凭据（包括即将过期）
  Future<bool> refreshAllOutDated() async {
    bool result = true;
    for (final credential in authCredentials.value.values) {
      if (credential.expireAt.isAfter(DateTime.now().addHours(3))) continue;
      final refreshResult = await currentSchoolSignal
          .value
          ?.platforms[credential.type]
          ?.refresh(credential);
      if (refreshResult == null) {
        result = false;
      } else {
        setAuthCredential(refreshResult.copyWith(guest: credential.guest));
      }
    }
    return result;
  }

  // 添加访客
  void addGuest(AuthCredential credential) {
    setAuthCredential(credential.copyWith(guest: true));
  }

  // 移除访客
  void removeGuest(String platformId, String id) {
    if (authIndexGuest.value[platformId] == null ||
        authIndexGuest.value[platformId]?[id] == null) {
      return;
    }
    removeAuthCredentialById(authIndexGuest.value[platformId]![id]!);
  }

  // 获取主账号
  AuthCredential? getPrimaryAuthByPlatform(String platformId) {
    return getPrimaryAuthCredentialByPlatform(platformId);
  }

  // 获取访客
  AuthCredential? getGuestAuthById(String platformId, String id) {
    return getGuestAuthCredentialById(platformId, id);
  }

  // 获取所有访客
  List<AuthCredential> getAllGuestAuthByPlatform(String platformId) {
    return getAllGuestAuthCredentialByPlatform(platformId);
  }

  // 检查访客是否存在
  bool hasGuest(AuthCredential credential) {
    return authCredentials.value.containsKey(genAuthCredentialGuid(credential));
  }
}
