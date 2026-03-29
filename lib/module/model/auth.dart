import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:punklorde/utils/etc/byte.dart';
import 'package:zstandard/zstandard.dart';

const List<int> shareDataMagicNum = [0x70, 0x6C, 0x53, 0x0D];

// 账号凭据
class AuthCredential {
  final bool guest; // 是否为访客账号
  final String type; // 凭据类型（Platform ID）
  final String id; // 凭据ID
  final String name; // 凭据显示名称
  final String token; // 凭据令牌
  final DateTime expireAt; // 凭据过期时间
  final Map<String, dynamic>? ext; // 凭据扩展信息

  AuthCredential({
    required this.guest,
    required this.type,
    required this.id,
    required this.name,
    required this.token,
    required this.expireAt,
    this.ext,
  });

  bool isValid() => DateTime.now().isBefore(expireAt);

  AuthCredential copyWith({
    bool? guest,
    String? type,
    String? id,
    String? name,
    String? token,
    DateTime? expireAt,
    Map<String, dynamic>? ext,
  }) {
    return AuthCredential(
      guest: guest ?? this.guest,
      type: type ?? this.type,
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      expireAt: expireAt ?? this.expireAt,
      ext: ext ?? this.ext,
    );
  }

  Map<String, dynamic> toJson() => {
    "guest": guest,
    "type": type,
    "id": id,
    "name": name,
    "token": token,
    "expire_at": expireAt.millisecondsSinceEpoch,
    "ext": ext,
  };

  factory AuthCredential.fromJson(Map<String, dynamic> json) => AuthCredential(
    guest: json['guest'] as bool,
    type: json['type'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    token: json['token'] as String,
    expireAt: DateTime.fromMillisecondsSinceEpoch(json['expire_at'] as int),
    ext: Map<String, dynamic>.from(json['ext'] as Map? ?? {}),
  );

  Map<String, dynamic> toCompactJson() => {
    "0": guest,
    "a": type,
    "i": id,
    "n": name,
    "k": token,
    "e": expireAt.millisecondsSinceEpoch,
    "x": ext,
  };

  factory AuthCredential.fromCompactJson(Map<String, dynamic> json) =>
      AuthCredential(
        guest: json['0'] as bool,
        type: json['a'] as String,
        id: json['i'] as String,
        name: json['n'] as String,
        token: json['k'] as String,
        expireAt: DateTime.fromMillisecondsSinceEpoch(json['e'] as int),
        ext: Map<String, dynamic>.from(json['x'] as Map? ?? {}),
      );

  List<int> toCbor() => cbor.encode(toJson());

  List<int> toComapctCbor() => cbor.encode(toCompactJson());

  factory AuthCredential.fromCbor(List<int> data) {
    final json = Map<String, dynamic>.from(
      cbor.decode(data) as Map<Object?, Object?>,
    );
    return AuthCredential.fromJson(json);
  }

  factory AuthCredential.fromComapctCbor(List<int> data) {
    final json = Map<String, dynamic>.from(
      cbor.decode(data) as Map<Object?, Object?>,
    );
    return AuthCredential.fromCompactJson(json);
  }

  String toCborString() => base64.encode(toCbor());

  factory AuthCredential.fromCborString(String data) {
    return AuthCredential.fromCbor(base64.decode(data));
  }

  Future<Uint8List?> toSharedData() async {
    final data = await Zstandard().compress(
      Uint8List.fromList(toComapctCbor()),
      16,
    );
    if (data == null) return null;
    return prependMagic(data, shareDataMagicNum);
  }

  static Future<AuthCredential?> fromSharedData(Uint8List data) async {
    try {
      final rawData = extractAfterMagic(data, shareDataMagicNum);
      final decoded = await Zstandard().decompress(rawData);
      if (decoded == null) return null;
      return AuthCredential.fromComapctCbor(decoded.toList());
    } catch (e) {
      return null;
    }
  }
}
