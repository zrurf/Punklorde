import 'dart:math';

/// 轨迹点
class TrajectoryPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? heading;

  const TrajectoryPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.heading,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'heading': heading,
  };

  factory TrajectoryPoint.fromJson(Map<String, dynamic> json) =>
      TrajectoryPoint(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        altitude: json['altitude'] as double?,
        heading: json['heading'] as double?,
      );

  /// 计算两点间距离（米），使用Haversine公式
  double distanceTo(TrajectoryPoint other) {
    const earthRadius = 6371000.0; // 地球半径（米）
    final lat1 = latitude * pi / 180;
    final lon1 = longitude * pi / 180;
    final lat2 = other.latitude * pi / 180;
    final lon2 = other.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}

/// Tag信息
class TagInfo {
  final String id;
  final Map<String, dynamic> ext;

  const TagInfo({required this.id, this.ext = const {}});

  Map<String, dynamic> toJson() => {'id': id, 'ext': ext};

  factory TagInfo.fromJson(Map<String, dynamic> json) => TagInfo(
    id: json['id'] as String,
    ext: Map<String, dynamic>.from(json['ext'] as Map? ?? {}),
  );
}

/// 点Tag（单个点）
class PointTag {
  final int pointIndex;
  final int tagInfoIndex;

  const PointTag({required this.pointIndex, required this.tagInfoIndex});

  Map<String, dynamic> toJson() => {
    'pointIndex': pointIndex,
    'tagInfoIndex': tagInfoIndex,
  };

  factory PointTag.fromJson(Map<String, dynamic> json) => PointTag(
    pointIndex: json['pointIndex'] as int,
    tagInfoIndex: json['tagInfoIndex'] as int,
  );
}

/// 区域Tag（区间）
class AreaTag {
  final int startIndex;
  final int endIndex;
  final int tagInfoIndex;

  const AreaTag({
    required this.startIndex,
    required this.endIndex,
    required this.tagInfoIndex,
  });

  Map<String, dynamic> toJson() => {
    'startIndex': startIndex,
    'endIndex': endIndex,
    'tagInfoIndex': tagInfoIndex,
  };

  factory AreaTag.fromJson(Map<String, dynamic> json) => AreaTag(
    startIndex: json['startIndex'] as int,
    endIndex: json['endIndex'] as int,
    tagInfoIndex: json['tagInfoIndex'] as int,
  );
}

/// 虚拟路径
class VirtualPath {
  final String id;
  final String name;
  final List<TrajectoryPoint> points;
  final double length;
  final List<PointTag> pointTags;
  final List<AreaTag> areaTags;
  final List<TagInfo> tagInfoPool;
  final Map<String, dynamic> smoothCurves;
  final Map<String, dynamic> ext;

  const VirtualPath({
    required this.id,
    required this.name,
    required this.points,
    required this.length,
    this.pointTags = const [],
    this.areaTags = const [],
    this.tagInfoPool = const [],
    this.smoothCurves = const {},
    this.ext = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'points': points.map((p) => p.toJson()).toList(),
    'length': length,
    'pointTags': pointTags.map((t) => t.toJson()).toList(),
    'areaTags': areaTags.map((t) => t.toJson()).toList(),
    'tagInfoPool': tagInfoPool.map((t) => t.toJson()).toList(),
    'smoothCurves': smoothCurves,
    'ext': ext,
  };

  factory VirtualPath.fromJson(Map<String, dynamic> json) => VirtualPath(
    id: json['id'] as String,
    name: json['name'] as String,
    points: (json['points'] as List)
        .map((p) => TrajectoryPoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    length: json['length'] as double,
    pointTags: (json['pointTags'] as List? ?? [])
        .map((t) => PointTag.fromJson(t as Map<String, dynamic>))
        .toList(),
    areaTags: (json['areaTags'] as List? ?? [])
        .map((t) => AreaTag.fromJson(t as Map<String, dynamic>))
        .toList(),
    tagInfoPool: (json['tagInfoPool'] as List? ?? [])
        .map((t) => TagInfo.fromJson(t as Map<String, dynamic>))
        .toList(),
    smoothCurves: Map<String, dynamic>.from(json['smoothCurves'] as Map? ?? {}),
    ext: Map<String, dynamic>.from(json['ext'] as Map? ?? {}),
  );
}

/// 运动配置
enum PlaybackMode { once, loop }

enum PlaybackOrder { sequential, random }

class MotionProfile {
  final String id;
  final String name;
  final List<VirtualPath> virtualPaths;
  final PlaybackMode playbackMode;
  final PlaybackOrder playbackOrder;
  final Map<String, dynamic> ext;

  const MotionProfile({
    required this.id,
    required this.name,
    required this.virtualPaths,
    this.playbackMode = PlaybackMode.once,
    this.playbackOrder = PlaybackOrder.sequential,
    this.ext = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'virtualPaths': virtualPaths.map((p) => p.toJson()).toList(),
    'playbackMode': playbackMode.name,
    'playbackOrder': playbackOrder.name,
    'ext': ext,
  };

  factory MotionProfile.fromJson(Map<String, dynamic> json) => MotionProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    virtualPaths: (json['virtualPaths'] as List)
        .map((p) => VirtualPath.fromJson(p as Map<String, dynamic>))
        .toList(),
    playbackMode: PlaybackMode.values.firstWhere(
      (e) => e.name == json['playbackMode'],
      orElse: () => PlaybackMode.once,
    ),
    playbackOrder: PlaybackOrder.values.firstWhere(
      (e) => e.name == json['playbackOrder'],
      orElse: () => PlaybackOrder.sequential,
    ),
    ext: Map<String, dynamic>.from(json['ext'] as Map? ?? {}),
  );

  /// 计算总路径长度
  double get totalLength =>
      virtualPaths.fold(0.0, (sum, path) => sum + path.length);
}
