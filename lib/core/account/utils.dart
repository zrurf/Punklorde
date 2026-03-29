import 'dart:convert';

import 'package:punklorde/module/model/auth.dart';
import 'package:xxh3/xxh3.dart';

// 生成认证凭证GUID
String genAuthCredentialGuid(AuthCredential credential) {
  return '${credential.type}_${xxh3String(utf8.encode(credential.id))}_${credential.guest ? 'g' : 'p'}';
}
