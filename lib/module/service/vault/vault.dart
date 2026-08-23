import 'dart:convert';
import 'dart:math';

import 'package:cbor/simple.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:local_auth/local_auth.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/module/model/vault.dart';

/// 密码保管库
///
/// 条目使用设备主密钥加密存储（主密钥随机生成，存放于 MMKV）。
/// 默认无锁；开启锁后可设置解锁密码与系统生物认证（指纹/人脸），
/// 开启后在每次进入保管库或填充密码时需完成一次认证。
class VaultService {
  static const String _kMasterKey = 'vault_master_key';
  static const String _kSalt = 'vault_salt';
  static const String _kPwdHash = 'vault_pwd_hash';
  static const String _kData = 'vault_data';
  static const String _kBiometric = 'vault_biometric';
  static const String _kLock = 'vault_lock';

  static const int _nonceLength = 12;
  static const int _macLength = 16;

  final AesGcm _cipher = AesGcm.with256bits();
  final Random _random = Random.secure();
  final StorageService _storage = StorageService();

  /// 是否已设置解锁密码
  bool get hasUnlockPassword =>
      _storage.getString(_kPwdHash, instance: defaultMMKV) != null;

  /// 是否已开启锁
  bool get lockEnabled => _storage.getBool(_kLock, instance: defaultMMKV);

  /// 是否启用了系统生物认证
  bool get biometricEnabled =>
      _storage.getBool(_kBiometric, instance: defaultMMKV);

  void setBiometricEnabled(bool value) {
    _storage.putBool(_kBiometric, value, instance: defaultMMKV);
    if (value) {
      _storage.putBool(_kLock, true, instance: defaultMMKV);
    }
  }

  /// 设备是否支持且已录入生物特征
  Future<bool> get biometricAvailable async {
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) return false;
      if (!await auth.canCheckBiometrics) return false;
      return (await auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 触发系统生物认证（不校验启用开关，由调用方判断）
  Future<bool> authenticateBiometric({String? localizedReason}) async {
    if (!(await biometricAvailable)) return false;
    try {
      return await LocalAuthentication().authenticate(
        localizedReason: localizedReason ?? 'Unlock vault',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      return false;
    }
  }

  /// 验证解锁密码
  bool verifyPassword(String password) {
    final hash = _storage.getString(_kPwdHash, instance: defaultMMKV);
    if (hash == null) return false;
    return _hashPwd(_saltStr(), password) == hash;
  }

  /// 设置/修改解锁密码（同时开启锁）
  Future<bool> setUnlockPassword(String password) async {
    final salt = _randomBytes(16);
    _storage.putString(_kSalt, base64.encode(salt), instance: defaultMMKV);
    _storage.putString(
      _kPwdHash,
      _hashPwd(_saltStr(), password),
      instance: defaultMMKV,
    );
    // 首次设置时生成设备主密钥
    if (!_storage.containsKey(_kMasterKey, instance: defaultMMKV)) {
      _storage.putString(
        _kMasterKey,
        base64.encode(_randomBytes(32)),
        instance: defaultMMKV,
      );
    }
    _storage.putBool(_kLock, true, instance: defaultMMKV);
    return true;
  }

  /// 取消锁（移除解锁密码与生物认证，条目数据保留）
  Future<void> disableLock() async {
    _storage.remove(_kPwdHash, instance: defaultMMKV);
    _storage.remove(_kSalt, instance: defaultMMKV);
    _storage.remove(_kBiometric, instance: defaultMMKV);
    _storage.putBool(_kLock, false, instance: defaultMMKV);
    _entriesCache = [];
  }

  String _saltStr() => _storage.getString(_kSalt, instance: defaultMMKV) ?? '';

  String _hashPwd(String salt, String password) =>
      base64.encode(sha256.convert(utf8.encode('$salt:$password')).bytes);

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  List<VaultEntry> _entriesCache = [];

  /// 获取全部条目（调用方需先完成认证）
  Future<List<VaultEntry>> entries() async {
    if (_entriesCache.isNotEmpty) return List.of(_entriesCache);
    _entriesCache = await _loadEntries();
    return List.of(_entriesCache);
  }

  /// 按账号类型匹配的条目
  Future<List<VaultEntry>> entriesByAccountType(String accountType) async {
    final all = await entries();
    return all.where((e) => e.accountType == accountType).toList();
  }

  Future<void> addEntry(VaultEntry entry) async {
    final list = await entries();
    list.add(entry);
    await _saveEntries(list);
  }

  Future<void> updateEntry(VaultEntry entry) async {
    final list = await entries();
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      list[index] = entry;
      await _saveEntries(list);
    }
  }

  Future<void> removeEntry(String id) async {
    final list = await entries();
    list.removeWhere((e) => e.id == id);
    await _saveEntries(list);
  }

  /// 保存条目（登录成功后经用户确认调用）
  Future<void> saveEntry({
    required String schoolId,
    required String platformId,
    required String accountType,
    required String username,
    required String password,
  }) async {
    if (username.isEmpty) return;
    final list = await _loadEntries();
    final existing = list.indexWhere(
      (e) => e.accountType == accountType && e.username == username,
    );
    if (existing >= 0) {
      list[existing] = list[existing].copyWith(
        schoolId: schoolId,
        platformId: platformId,
        password: password,
      );
    } else {
      list.add(
        VaultEntry(
          id: VaultEntry.newId(),
          schoolId: schoolId,
          platformId: platformId,
          accountType: accountType,
          username: username,
          password: password,
          createdAt: DateTime.now(),
        ),
      );
    }
    _entriesCache = List.of(list);
    await _saveEntries(list);
  }

  List<int> _masterKey() =>
      base64.decode(_storage.getString(_kMasterKey, instance: defaultMMKV)!);

  Future<List<VaultEntry>> _loadEntries() async {
    final raw = _storage.getString(_kData, instance: defaultMMKV);
    if (raw == null) return [];
    try {
      final payload = base64.decode(raw);
      if (payload.length < _nonceLength + _macLength) return [];
      final nonce = payload.sublist(0, _nonceLength);
      final mac = payload.sublist(payload.length - _macLength);
      final cipherText = payload.sublist(
        _nonceLength,
        payload.length - _macLength,
      );
      final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
      final clear = await _cipher.decrypt(
        box,
        secretKey: SecretKey(_masterKey()),
      );
      final decoded = cbor.decode(clear) as List;
      return decoded
          .map(
            (e) => VaultEntry.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveEntries(List<VaultEntry> entries) async {
    _entriesCache = List.of(entries);
    if (!_storage.containsKey(_kMasterKey, instance: defaultMMKV)) {
      _storage.putString(
        _kMasterKey,
        base64.encode(_randomBytes(32)),
        instance: defaultMMKV,
      );
    }
    final bytes = cbor.encode(entries.map((e) => e.toJson()).toList());
    final nonce = _randomBytes(_nonceLength);
    final box = await _cipher.encrypt(
      bytes,
      secretKey: SecretKey(_masterKey()),
      nonce: nonce,
    );
    final payload = <int>[...nonce, ...box.cipherText, ...box.mac.bytes];
    _storage.putString(_kData, base64.encode(payload), instance: defaultMMKV);
  }
}

final VaultService vaultService = VaultService();
