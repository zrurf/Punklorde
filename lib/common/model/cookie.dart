import 'package:cookie_jar/cookie_jar.dart';

/// CookieJar 转 Map
Future<Map<String, List<Cookie>>> mapCookieJar(
  CookieJar cookieJar,
  Set<String> uris,
) async {
  final Map<String, List<Cookie>> cookies = {};
  for (final uri in uris) {
    final cookie = await cookieJar.loadForRequest(Uri.parse(uri));
    cookies[uri.toString()] = cookie;
  }
  return cookies;
}

/// Map 转 CookieJar
Future<CookieJar> fromCookieJarMap(Map<String, List<Cookie>> cookies) async {
  final cookieJar = CookieJar();
  for (final entry in cookies.entries) {
    await cookieJar.saveFromResponse(Uri.parse(entry.key), entry.value);
  }
  return cookieJar;
}

/// 序列化Cookie Jar
Future<Map<String, List<String>>> serializeCookieJar(
  CookieJar cookieJar,
  Set<String> uris,
) async {
  final jar = await mapCookieJar(cookieJar, uris);
  final Map<String, List<String>> cookies = jar.map((k, v) {
    return MapEntry(k, v.map((e) => SerializableCookie(e).toJson()).toList());
  });
  return cookies;
}

/// 反序列化Cookie Jar
Future<CookieJar> deserializeCookieJar(
  Map<String, List<String>> cookies,
) async {
  final Map<String, List<Cookie>> jar = {};
  for (final entry in cookies.entries) {
    jar[entry.key] = [];
    for (final cookie in entry.value) {
      jar[entry.key]!.add(SerializableCookie.fromJson(cookie).cookie);
    }
  }
  return await fromCookieJarMap(jar);
}
