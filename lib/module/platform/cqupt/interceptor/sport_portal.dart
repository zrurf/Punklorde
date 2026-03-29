import 'package:dio/dio.dart';

// CQUPT 智慧体育门户 拦截器
class CquptSportPortalInterceptor extends Interceptor {
  String? _token;

  CquptSportPortalInterceptor({String? token}) : _token = token;

  void setToken(String? token) {
    _token = token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    (_token != null)
        ? options.headers["Authorization"] = "Bearer $_token"
        : options.headers.remove("Authorization");
    options.headers["Origin"] = "http://172.20.2.228";
    options.headers["X-FS-ORG"] = 'cqupt';
    options.headers["X-FS-TYPE"] = "portal-mobile";
    handler.next(options);
  }
}
