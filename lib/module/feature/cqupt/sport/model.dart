import 'dart:convert';

import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/src/rust/services/motion_sim/model.dart';
import 'package:xxh3/xxh3.dart';

/// 运动模式
enum SportMode { normal, auto, record }

final Map<SportMode, String> modeNames = {
  SportMode.normal: t.submodule.cqupt_sport.mode_normal_run,
  SportMode.auto: t.submodule.cqupt_sport.mode_auto_run,
  SportMode.record: t.submodule.cqupt_sport.mode_traj_record,
};

/// 自动跑步配置
class AutoRunningConfig {
  final String placeCode;
  final String placeName;
  final int updateFrequency;
  final double targetDistance;
  final SimulatorConfig simulatorConfig;
  final List<Trajectory> trajectories;

  const AutoRunningConfig({
    required this.placeCode,
    required this.placeName,
    required this.updateFrequency,
    required this.targetDistance,
    required this.simulatorConfig,
    required this.trajectories,
  });
}

/// 上传回调结果
class UploadCallbackRsult {
  final double distance;
  final num time;
  final num forbiddenCount;

  const UploadCallbackRsult({
    required this.distance,
    required this.time,
    required this.forbiddenCount,
  });
}

/// 索引schema
class IndexSchema {
  final List<ResourceIndexEntry> map;

  IndexSchema({required this.map});

  factory IndexSchema.fromJson(Map<String, dynamic> json) {
    return IndexSchema(
      map: (json['map'] as List)
          .map(
            (item) => ResourceIndexEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'map': map.map((item) => item.toJson()).toList()};
  }
}

/// 资源索引项
class ResourceIndexEntry {
  final String id;
  final String name;
  final String path;

  const ResourceIndexEntry({
    required this.id,
    required this.name,
    required this.path,
  });

  factory ResourceIndexEntry.fromJson(Map<String, dynamic> json) {
    return ResourceIndexEntry(
      id: json['id'],
      name: json['name'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'path': path};
  }
}

/// 运动配置
class MotionProfile {
  /// 运动文件的唯一ID
  final String id;

  /// 运动文件的版本
  final int version;

  /// 作者
  final String? author;

  /// 显示的运动文件的名称
  final String name;

  /// 运动文件的描述
  final String? description;

  /// 查找轨迹文件的链接
  final List<String>? repo;

  /// 运动数据
  final MotionProfileData? data;

  MotionProfile({
    required this.id,
    required this.version,
    this.author,
    required this.name,
    this.description,
    this.repo,
    this.data,
  });

  factory MotionProfile.fromJson(Map<String, dynamic> json) => MotionProfile(
    id: json['id'],
    version: json['version'],
    author: json['author'],
    name: json['name'],
    description: json['description'],
    repo: json['repo'] != null ? List<String>.from(json['repo']) : null,
    data: json['data'] != null
        ? MotionProfileData.fromJson(json['data'])
        : null,
  );
}

/// 运动配置数据
class MotionProfileData {
  /// 虚拟路径
  final List<String> paths;

  /// 扩展字段（任意对象）
  final Map<String, dynamic>? ext;

  MotionProfileData({required this.paths, this.ext});

  factory MotionProfileData.fromJson(Map<String, dynamic> json) =>
      MotionProfileData(
        paths: List<String>.from(json['paths']),
        ext: Map<String, dynamic>.from(json['ext'] ?? {}),
      );
}

/// 虚拟路径
class VirtualPath {
  /// 路线的唯一ID
  final String id;

  /// 路线的版本
  final int version;

  /// 作者
  final String? author;

  /// 显示的路线的名称
  final String name;

  /// 路线的描述
  final String? description;

  /// 路线点
  final List<VirtualPathPoint> points;

  VirtualPath({
    required this.id,
    required this.version,
    this.author,
    required this.name,
    this.description,
    required this.points,
  });

  factory VirtualPath.fromJson(Map<String, dynamic> json) => VirtualPath(
    id: json['id'] as String,
    version: json['version'] as int,
    author: json['author'] as String?,
    name: json['name'] as String,
    description: json['description'] as String?,
    points: (json['points'] as List)
        .map((e) => VirtualPathPoint.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// 虚拟运动路径点
class VirtualPathPoint {
  /// 纬度
  final double lat;

  /// 经度
  final double lng;

  /// 海拔（可选）
  final double? alt;

  VirtualPathPoint({required this.lat, required this.lng, this.alt});

  factory VirtualPathPoint.fromJson(Map<String, dynamic> json) =>
      VirtualPathPoint(
        lat: json['lat'] as double,
        lng: json['lng'] as double,
        alt: json['alt'] as double?,
      );
}

/// 用户配置
class UserConfig {
  final double targetDistance; // 目标距离
  final double speed; // 速度

  final int interval; // 刷新间隔(ms)
  final String? seed; // 随机种子
  final double positionJitterAmplitude; // 位置抖动幅度
  final double speedJitterAmplitude; // 速度抖动幅度

  UserConfig({
    this.targetDistance = 2100,
    this.speed = 3.1,
    this.interval = 1000,
    this.seed,
    this.positionJitterAmplitude = 0.1,
    this.speedJitterAmplitude = 0.3,
  });

  BigInt seedToBigInt() {
    if (seed == null) return BigInt.from(DateTime.now().millisecondsSinceEpoch);
    return BigInt.from(int.tryParse(seed!) ?? xxh3(utf8.encode(seed!)));
  }

  UserConfig copyWith({
    double? targetDistance,
    double? speed,
    int? interval,
    String? seed,
    double? positionJitterAmplitude,
    double? speedJitterAmplitude,
  }) {
    return UserConfig(
      targetDistance: targetDistance ?? this.targetDistance,
      speed: speed ?? this.speed,
      interval: interval ?? this.interval,
      seed: seed ?? this.seed,
      positionJitterAmplitude:
          positionJitterAmplitude ?? this.positionJitterAmplitude,
      speedJitterAmplitude: speedJitterAmplitude ?? this.speedJitterAmplitude,
    );
  }
}

/// 运动统计数据
class SportStatistics {
  final int targetTotalCount; // 运动目标总数
  final int targetRunCount; // 运动目标中跑步总数
  final int targetOtherCount; // 运动目标中其他总数
  final int totalCount; // 运动总数
  final int runCount; // 跑步总数
  final int otherCount; // 其他总数
  final int totalExamCount; // 计入考试运动总数
  final int runExamCount; // 计入考试运动中跑步总数
  final int otherExamCount; // 计入考试运动中其他总数
  final int totalAddCount; // 附加运动总数
  final int runAddCount; // 附加运动中跑步总数
  final int otherAddCount; // 附加运动中其他总数

  const SportStatistics({
    required this.targetTotalCount,
    required this.targetRunCount,
    required this.targetOtherCount,
    required this.totalCount,
    required this.runCount,
    required this.otherCount,
    required this.totalExamCount,
    required this.runExamCount,
    required this.otherExamCount,
    required this.totalAddCount,
    required this.runAddCount,
    required this.otherAddCount,
  });

  factory SportStatistics.fromJson(Map<String, dynamic> json) =>
      SportStatistics(
        targetTotalCount:
            json["totalCountNeed"] ??
            (json["raceCountNeed"] + json["otherCountNeed"]),
        targetRunCount:
            json["raceCountNeed"] ??
            (json["totalCountNeed"] - json["raceCountNeed"]),
        targetOtherCount:
            json["otherCountNeed"] ??
            (json["totalCountNeed"] - json["raceCountNeed"]),
        totalCount:
            json["totalCount"] ?? (json["raceCount"] + json["otherCount"]),
        runCount: json["raceCount"],
        otherCount: json["otherCount"],
        totalExamCount:
            json["examTime"] ?? (json["raceExamTime"] + json["otherExamTime"]),
        runExamCount: json["raceExamTime"],
        otherExamCount: json["otherExamTime"],
        totalAddCount:
            json["attachTime"] ??
            (json["raceAttachTime"] + json["otherAttachTime"]),
        runAddCount: json["raceAttachTime"],
        otherAddCount: json["otherAttachTime"],
      );
}
