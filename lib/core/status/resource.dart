import 'package:dio/dio.dart';
import 'package:punklorde/core/resource/cache.dart';
import 'package:punklorde/core/resource/manager.dart';
import 'package:punklorde/core/resource/model.dart';

// 资源管理器
late final ResourceManager resourceManager;

// 初始化资源管理器
Future<void> setupResourceManager({
  required Dio dio,
  required List<Source> sources,
}) async {
  final cacheService = CacheService();
  await cacheService.init();

  // 实例化并赋值给全局变量
  resourceManager = ResourceManager(dio: dio, cacheService: cacheService);

  resourceManager.sourcesSignal.value = sources;
}
