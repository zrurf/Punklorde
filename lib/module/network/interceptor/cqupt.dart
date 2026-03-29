import 'package:dio/dio.dart';

// CQUPT X-Forward-For header 拦截器
class CquptForwardInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Forwarded-For'] = '172.16.0.1';
    handler.next(options);
  }
}
