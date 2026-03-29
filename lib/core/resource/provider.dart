import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:punklorde/core/resource/model.dart';

/// Provider 抽象基类
abstract class ResourceProvider {
  Future<Uint8List?> load(String relativePath);
}

/// 本地资源 Provider (加载 Flutter Assets 或本地文件)
class LocalAssetProvider implements ResourceProvider {
  @override
  Future<Uint8List?> load(String relativePath) async {
    try {
      // 示例：加载 Flutter 内置 assets，或者扫描本地特定目录
      // 这里仅作演示，实际需根据业务调整
      // final data = await rootBundle.load('assets/$relativePath');
      // return data.buffer.asUint8List();
      return null; // 暂时返回 null，假设本地主要靠缓存
    } catch (e) {
      return null;
    }
  }
}

/// 远程资源 Provider (使用 Dio，支持源列表)
class RemoteProvider implements ResourceProvider {
  final Dio dio;
  final List<Source> Function() getSources; // 动态获取最新源列表

  RemoteProvider({required this.dio, required this.getSources});

  @override
  Future<Uint8List?> load(String relativePath) async {
    final sources = getSources().where((s) => s.enabled).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (sources.isEmpty) return null;

    // 遍历源列表尝试下载
    for (final source in sources) {
      try {
        final url = '${source.baseUrl}/$relativePath';
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data != null) {
          return Uint8List.fromList(response.data!);
        }
      } on DioException catch (e) {
        print('Failed to load from ${source.id}: ${e.message}');
        // 继续尝试下一个源
        continue;
      }
    }
    return null; // 所有源都失败
  }
}
