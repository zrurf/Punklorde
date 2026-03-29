import 'package:dio/dio.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/utils/ua.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  // 标记是否正在刷新，防止重复刷新
  bool _isRefreshing = false;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 自动注入 Header
    final token = featCredential.value?.token;
    if (token != null && token.isNotEmpty) {
      options.headers['token'] = token;
    }

    // 添加公共 Header
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    options.headers['User-Agent'] = UAUtil.getUA(UAType.wxapplet);

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 检查业务状态码 code 为 "40401" 或 "40402" 时刷新
    final data = response.data;

    // 确保返回数据是 Map 且包含 code 字段
    if (data is Map<String, dynamic> && data['code'] != null) {
      final code = data['code'].toString();

      if (code == '40401' || code == '40402') {
        // 检查是否已经重试过，防止死循环
        if (response.requestOptions.extra['alreadyRetried'] == true) {
          // 如果已经重试过仍然失败，则直接返回失败，不再刷新
          return handler.next(response);
        }

        // 执行刷新逻辑
        _handleTokenExpired(response.requestOptions, handler);
        return; // 阻止本次响应继续传递，等待刷新结果
      }
    }

    // code 为 "10200" 或其他正常情况，直接放行
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      if (err.requestOptions.extra['alreadyRetried'] != true) {
        _handleTokenExpired(err.requestOptions, handler);
        return;
      }
    }
    handler.next(err);
  }

  Future<void> _handleTokenExpired(
    RequestOptions requestOptions,
    dynamic handler, // 可能是 ResponseInterceptorHandler 或 ErrorInterceptorHandler
  ) async {
    // 获取当前凭证
    final currentCredential = featCredential.value;
    if (currentCredential == null) {
      // 没有凭证，无法刷新，直接结束
      _finishHandler(
        handler,
        null,
        requestOptions,
        DioException(requestOptions: requestOptions, error: "No credential"),
      );
      return;
    }

    // 刷新 Token
    if (!_isRefreshing) {
      _isRefreshing = true;

      try {
        // 调用你已有的刷新方法
        final newCredential = await authManager.refreshAndGetByCredential(
          currentCredential,
        );

        if (newCredential != null) {
          featCredential.value = newCredential;
          _isRefreshing = false;
          _retry(requestOptions, handler);
        } else {
          _isRefreshing = false;
          _finishHandler(
            handler,
            null,
            requestOptions,
            DioException(
              requestOptions: requestOptions,
              error: "Refresh failed",
            ),
          );
        }
      } catch (e) {
        _isRefreshing = false;
        _finishHandler(
          handler,
          null,
          requestOptions,
          DioException(requestOptions: requestOptions, error: e),
        );
      }
    } else {
      _retry(requestOptions, handler);
    }
  }

  Future<void> _retry(RequestOptions requestOptions, dynamic handler) async {
    // 标记为已重试
    requestOptions.extra['alreadyRetried'] = true;

    // 更新 Header 中的 Token
    final newToken = featCredential.value?.token;
    if (newToken != null) {
      requestOptions.headers['token'] = newToken;
    }

    try {
      // 发起重试请求
      final response = await dio.fetch(requestOptions);
      // 重试成功，将结果传递给原始调用方
      _finishHandler(handler, response, requestOptions, null);
    } catch (e) {
      // 重试失败，返回错误
      if (e is DioException) {
        _finishHandler(handler, null, requestOptions, e);
      } else {
        _finishHandler(
          handler,
          null,
          requestOptions,
          DioException(requestOptions: requestOptions, error: e),
        );
      }
    }
  }

  void _finishHandler(
    dynamic handler,
    Response? response,
    RequestOptions requestOptions,
    DioException? error,
  ) {
    if (handler is ResponseInterceptorHandler) {
      if (error != null) {
        handler.reject(error);
      } else if (response != null) {
        handler.resolve(response);
      }
    } else if (handler is ErrorInterceptorHandler) {
      if (response != null) {
        handler.resolve(response);
      } else {
        handler.next(error ?? DioException(requestOptions: requestOptions));
      }
    }
  }
}
