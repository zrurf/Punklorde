import 'package:cookie_jar/cookie_jar.dart';
import 'package:punklorde/common/model/cookie.dart';
import 'package:punklorde/module/model/auth.dart';

/// 超星登录凭证缓存
/// 为避免cookie反复反序列化，因此封装一层cache
class AuthCredentialCache {
  final AuthCredential credential;
  final CookieJar cookie;

  const AuthCredentialCache({required this.credential, required this.cookie});

  static Future<AuthCredentialCache> fromCredential(
    AuthCredential credential,
  ) async {
    final rawMap = credential.ext!['cookie'] as Map<Object?, Object?>;
    final cookieMap = rawMap.map((key, value) {
      return MapEntry(key.toString(), List<String>.from(value as List));
    });
    final cookie = await deserializeCookieJar(cookieMap);
    return AuthCredentialCache(credential: credential, cookie: cookie);
  }
}
