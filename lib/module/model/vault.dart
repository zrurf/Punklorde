import 'package:cbor/simple.dart';
import 'package:uuid/uuid.dart';

/// 保管库条目
class VaultEntry {
  final String id; // 条目ID
  final String schoolId; // 学校ID
  final String platformId; // 平台ID
  final String accountType; // 登录账号类型（默认 = 平台ID，特例为统一认证ID）
  final String username; // 账号
  final String password; // 密码
  final String? remark; // 备注
  final DateTime createdAt; // 创建时间

  const VaultEntry({
    required this.id,
    required this.schoolId,
    required this.platformId,
    required this.accountType,
    required this.username,
    required this.password,
    this.remark,
    required this.createdAt,
  });

  VaultEntry copyWith({
    String? schoolId,
    String? platformId,
    String? accountType,
    String? username,
    String? password,
    String? remark,
  }) {
    return VaultEntry(
      id: id,
      schoolId: schoolId ?? this.schoolId,
      platformId: platformId ?? this.platformId,
      accountType: accountType ?? this.accountType,
      username: username ?? this.username,
      password: password ?? this.password,
      remark: (remark == null) ? this.remark : remark,
      createdAt: createdAt,
    );
  }

  static String newId() => const Uuid().v4();

  Map<String, dynamic> toJson() => {
    "id": id,
    "school_id": schoolId,
    "platform_id": platformId,
    "account_type": accountType,
    "username": username,
    "password": password,
    if (remark != null) "remark": remark,
    "created_at": createdAt.millisecondsSinceEpoch,
  };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
    id: json['id'] as String,
    schoolId: json['school_id'] as String,
    platformId: json['platform_id'] as String,
    accountType: json['account_type'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
    remark: json['remark'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      json['created_at'] as int,
    ),
  );

  List<int> toCbor() => cbor.encode(toJson());

  factory VaultEntry.fromCbor(List<int> data) {
    final json = Map<String, dynamic>.from(
      cbor.decode(data) as Map<Object?, Object?>,
    );
    return VaultEntry.fromJson(json);
  }
}