import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CacheService {
  late final Directory _cacheDir;

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'resource_cache'));
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
  }

  /// 获取缓存文件路径
  String getCachePath(String key) {
    // 对key进行简单处理防止路径穿越，实际生产建议使用md5(key)
    final safeName = key.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return p.join(_cacheDir.path, safeName);
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

  /// 读取缓存
  Future<String?> readCache(String key) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// 保存数据到缓存
  Future<String> saveCache(String key, List<int> data) async {
    final filePath = getCachePath(key);
    final file = File(filePath);
    await file.writeAsBytes(data, flush: true);
    return filePath;
  }
}
