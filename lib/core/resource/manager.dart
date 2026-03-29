import 'dart:io';

import 'package:punklorde/core/resource/cache.dart';
import 'package:punklorde/core/resource/model.dart';
import 'package:punklorde/core/resource/provider.dart';
import 'package:signals/signals.dart';
import 'package:dio/dio.dart';

class ResourceManager {
  final CacheService _cacheService;
  final Dio _dio;

  // 状态：源列表
  late final Signal<List<Source>> sourcesSignal;

  // 状态：资源加载状态 Map
  final Map<String, Signal<ResourceState>> _resourceSignals = {};

  // Provider 链
  late final RemoteProvider _remoteProvider;
  final LocalAssetProvider _localProvider = LocalAssetProvider();

  ResourceManager({required Dio dio, required CacheService cacheService})
    : _dio = dio,
      _cacheService = cacheService {
    // 初始化源列表 Signal
    sourcesSignal = signal([]);

    // 初始化远程 Provider，注入获取最新源列表的方法
    _remoteProvider = RemoteProvider(
      dio: _dio,
      getSources: () => sourcesSignal.value,
    );
  }

  /// 获取某个资源的响应式状态
  Signal<ResourceState> watchResource(String key) {
    return _resourceSignals.putIfAbsent(key, () => signal(ResourceState()));
  }

  /// 核心加载逻辑
  Future<String?> loadResource(
    String key, {
    Duration expiry = const Duration(hours: 24),
    bool forceRemote = false, // 强制忽略缓存，检查更新
  }) async {
    final resourceSignal = watchResource(key);

    // 1. 检查缓存 (如果不是强制更新)
    if (!forceRemote) {
      final isValid = await _cacheService.isCacheValid(key, expiry);
      if (isValid) {
        final path = await _cacheService.readCache(key);
        resourceSignal.value = ResourceState(
          status: ResourceStatus.localLoaded,
          localPath: path,
        );
        return path;
      }
    }

    // 2. 缓存无效或强制更新，开始远程加载
    resourceSignal.value = resourceSignal.value.copyWith(
      status: ResourceStatus.loading,
      progress: 0.0,
    );

    try {
      // 这里可以结合 Dio 的 onReceiveProgress 更新进度
      final bytes = await _remoteProvider.load(key);

      if (bytes != null) {
        // 3. 保存到缓存
        final path = await _cacheService.saveCache(key, bytes);
        resourceSignal.value = ResourceState(
          status: ResourceStatus.remoteLoaded,
          localPath: path,
          progress: 1.0,
        );
        return path;
      } else {
        throw Exception('All sources failed');
      }
    } catch (e) {
      // 4. 降级处理：如果远程失败，尝试读取旧缓存（即使过期）
      final path = await _cacheService.readCache(key);
      if (path != null) {
        resourceSignal.value = ResourceState(
          status: ResourceStatus.localLoaded, // 标记为本地加载
          localPath: path,
          error: e.toString(), // 附带错误信息
        );
        return path;
      }

      // 5. 彻底失败
      resourceSignal.value = ResourceState(
        status: ResourceStatus.error,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 手动检查更新
  Future<void> checkForUpdate(String key) async {
    await loadResource(key, forceRemote: true);
  }

  /// 清除特定缓存
  Future<void> clearCache(String key) async {
    final file = File(_cacheService.getCachePath(key));
    if (await file.exists()) {
      await file.delete();
    }
    if (_resourceSignals.containsKey(key)) {
      _resourceSignals[key]!.value = ResourceState();
    }
  }
}
