import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ConditionalRedirectInterceptor extends Interceptor {
  final Dio dio;

  // 注入 CookieJar 实例
  final CookieJar? cookieJar;

  final bool Function(Uri location) shouldStop;
  final bool Function(int statusCode, String originalMethod) shouldConvertToGet;
  final int maxRedirects;

  ConditionalRedirectInterceptor({
    required this.dio,
    required this.shouldStop,
    this.cookieJar,
    this.maxRedirects = 5,
    bool Function(int statusCode, String originalMethod)? shouldConvertToGet,
  }) : shouldConvertToGet = shouldConvertToGet ?? _defaultShouldConvertToGet;

  static bool _defaultShouldConvertToGet(
    int statusCode,
    String originalMethod,
  ) {
    return statusCode == 303;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final status = response.statusCode;

    // 1. 只处理 3xx 状态码
    if (status == null || status < 300 || status >= 400) {
      return handler.next(response);
    }

    // 2. 保存 302 响应中的 Cookie
    // 这一步确保服务器在重定向时设置的 Cookie (如登录态) 不会丢失
    if (cookieJar != null) {
      final setCookies = response.headers['set-cookie'];
      if (setCookies != null && setCookies.isNotEmpty) {
        // 将 Set-Cookie 字符串转换为 Cookie 对象
        final cookies = setCookies.map((str) {
          // 注意：这里使用 dart:io 的 Cookie 类，或 cookie_jar 中的实现
          // cookie_jar 中的 Cookie 类解析能力较强
          return Cookie.fromSetCookieValue(str);
        }).toList();

        await cookieJar!.saveFromResponse(response.requestOptions.uri, cookies);
      }
    }

    final locationHeader = response.headers.value('location');
    if (locationHeader == null) {
      return handler.next(response);
    }

    final requestUri = response.requestOptions.uri;
    final locationUri = requestUri.resolve(locationHeader);

    if (shouldStop(locationUri)) {
      return handler.next(response);
    }

    final redirectCount =
        (response.requestOptions.extra['redirect_count'] as int?) ?? 0;
    if (redirectCount >= maxRedirects) {
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          message: 'Exceeded max redirects ($maxRedirects)',
        ),
      );
    }

    // 3. 准备新请求
    RequestOptions newOptions = response.requestOptions.copyWith(
      path: locationUri.toString(),
      extra: {
        ...response.requestOptions.extra,
        'redirect_count': redirectCount + 1,
      },
    );

    // 4. 为新请求加载正确的 Cookie
    if (cookieJar != null) {
      // 先移除旧的 Cookie Header，防止冲突
      newOptions.headers.remove('cookie');

      // 从 Jar 中根据新 URL 加载 Cookie
      final cookies = await cookieJar!.loadForRequest(locationUri);
      if (cookies.isNotEmpty) {
        // 将 Cookie 拼接成字符串
        final cookieString = cookies
            .map((c) => '${c.name}=${c.value}')
            .join('; ');
        newOptions.headers['cookie'] = cookieString;
      }
    } else {
      // 如果没有 Jar，则回退到之前的逻辑（同源保留，跨域移除）
      final isCrossSite =
          requestUri.host != locationUri.host ||
          requestUri.port != locationUri.port;
      if (isCrossSite) {
        newOptions.headers.remove('cookie');
        newOptions.headers.remove('authorization');
      }
    }

    // 5. 处理 Host Header
    if (requestUri.host != locationUri.host) {
      newOptions.headers.remove('host');
    }

    // 6. 处理请求方法变更
    final originalMethod = newOptions.method.toUpperCase();
    final needConvertToGet = shouldConvertToGet(status, originalMethod);

    if (needConvertToGet) {
      if (originalMethod != 'GET' && originalMethod != 'HEAD') {
        newOptions.method = 'GET';
        newOptions.data = null;
        newOptions.headers.remove('content-type');
        newOptions.headers.remove('content-length');
      }
    }

    try {
      final newResponse = await dio.fetch(newOptions);
      return handler.resolve(newResponse);
    } catch (e) {
      return handler.reject(e as DioException);
    }
  }
}
