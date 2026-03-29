import 'package:cbor/simple.dart';
import 'package:punklorde/core/status/app.dart';

class Vault {
  final String id; // 保管器ID
  final String name; // 保管器名称
  final String username; // 账号名称
  final String password; // 密码（如果开启安全存储则为密文）

  Vault({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
  });

  Future<String?> getPassword() async {
    if (useSafeStorage.value) {
      return password;
    } else {
      return password;
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "username": username,
    "password": password,
  };

  factory Vault.fromJson(Map<String, dynamic> json) => Vault(
    id: json['id'] as String,
    name: json['name'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
  );

  List<int> toCbor() => cbor.encode(toJson());

  factory Vault.fromCbor(List<int> data) {
    final json = Map<String, dynamic>.from(
      cbor.decode(data) as Map<Object?, Object?>,
    );
    return Vault.fromJson(json);
  }
}
