class ModTongtianAuth {
  String? openid;
  String token;
  String publicKey;

  ModTongtianAuth({required this.token, required this.publicKey});

  factory ModTongtianAuth.fromJson(Map<String, dynamic> json) {
    return ModTongtianAuth(token: json['token'], publicKey: json['publicKey']);
  }
}
