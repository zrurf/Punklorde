import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:punklorde/core/resource/model.dart';

class CacheService {
  late final Directory _cacheDir;
  File? _accessedFile;

  // key -> 最近使用时间（由应用自行记录，避免依赖文件系统 atime）
  Map<String, DateTime> _accessedAt = {};

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'resource_cache'));
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _accessedFile = File(p.join(_cacheDir.path, '.last_accessed.json'));
    await _loadAccessedAt();
  }

  Future<void> _loadAccessedAt() async {
    final file = _accessedFile;
    if (file == null || !await file.exists()) return;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) return;
      _accessedAt = {
        for (final e in json.entries)
          if (e.value is String && DateTime.tryParse(e.value as String) != null)
            e.key: DateTime.parse(e.value as String),
      };
    } catch (_) {
      _accessedAt = {};
    }
  }

  Future<void> _persistAccessedAt() async {
    final file = _accessedFile;
    if (file == null) return;
    final data = {
      for (final e in _accessedAt.entries) e.key: e.value.toIso8601String(),
    };
    try {
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // 持久化失败不阻塞业务
    }
  }

  void _recordAccess(String key) {
    _accessedAt[key] = DateTime.now();
  }

  /// 获取缓存目录路径
  String get cacheDirPath => _cacheDir.path;

  /// 获取缓存文件路径（key 中可含 / 以使用子目录）
  String getCachePath(String key) {
    return p.join(_cacheDir.path, key);
  }

  /// 列出所有缓存条目
  Future<List<CacheEntry>> listCacheEntries() async {
    if (!await _cacheDir.exists()) return [];

    final entries = <CacheEntry>[];
    await for (final entity
        in _cacheDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final stat = await entity.stat();
        final relativePath = p.relative(entity.path, from: _cacheDir.path);
        // 忽略元数据文件
        if (p.basename(relativePath).startsWith('.')) continue;
        entries.add(
          CacheEntry(
            key: p.split(relativePath).join('/'),
            filePath: entity.path,
            size: stat.size,
            lastModified: stat.modified,
            // 使用应用自行记录的最近使用时间；文件系统 atime 在多数设备上
            // 并不可靠（常等于创建/修改时间），因此不再回退到 stat.accessed
            lastAccessed: _accessedAt[p.split(relativePath).join('/')],
          ),
        );
      }
    }
    entries.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return entries;
  }

  /// 获取缓存总大小（字节）
  Future<int> getTotalCacheSize() async {
    final entries = await listCacheEntries();
    var total = 0;
    for (final e in entries) {
      total += e.size;
    }
    return total;
  }

  /// 检查缓存是否存在且未过期
  Future<bool> isCacheValid(String key, Duration expiryDuration) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (!await file.exists()) return false;

    final stat = await file.stat();
    final age = DateTime.now().difference(stat.modified);
    return age < expiryDuration;
  }

  /// 读取缓存（会更新该缓存的“最后使用时间”）
  Future<String?> readCache(String key) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (await file.exists()) {
      _recordAccess(key);
      unawaited(_persistAccessedAt());
      return filePath;
    }
    return null;
  }

  /// 删除单个缓存
  Future<bool> deleteCache(String key) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      // 清理空父目录
      final dir = file.parent;
      if (dir.path != _cacheDir.path && await dir.exists()) {
        final contents = await dir.list().toList();
        if (contents.isEmpty) {
          await dir.delete();
        }
      }
      _accessedAt.remove(key);
      unawaited(_persistAccessedAt());
      return true;
    }
    return false;
  }

  /// 清除所有缓存
  Future<int> clearAllCache() async {
    if (!await _cacheDir.exists()) return 0;

    var count = 0;
    await for (final entity
        in _cacheDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        count++;
      }
    }
    await _cacheDir.delete(recursive: true);
    await _cacheDir.create(recursive: true);
    _accessedAt = {};
    return count;
  }

  /// 保存数据到缓存
  Future<String> saveCache(String key, List<int> data) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data, flush: true);
    _recordAccess(key);
    unawaited(_persistAccessedAt());
    return filePath;
  }
}