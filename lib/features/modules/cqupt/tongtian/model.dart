enum RunState { idle, running, paused }

class RunConfig {
  final double speed; // 速度
  final double distance; // 目标里程
  final int interval; // 毫秒每次
  final bool useJitter; // 是否启用抖动

  const RunConfig({
    this.speed = 3.2,
    required this.distance,
    this.interval = 1000,
    this.useJitter = true,
  });

  RunConfig copyWith({
    double? speed,
    double? distance,
    int? interval,
    bool? useJitter,
  }) {
    return RunConfig(
      speed: speed ?? this.speed,
      distance: distance ?? this.distance,
      interval: interval ?? this.interval,
      useJitter: useJitter ?? this.useJitter,
    );
  }
}

class IndexSchema {
  final List<MapItem> map;

  IndexSchema({required this.map});

  factory IndexSchema.fromJson(Map<String, dynamic> json) {
    return IndexSchema(
      map: (json['map'] as List)
          .map((item) => MapItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'map': map.map((item) => item.toJson()).toList()};
  }
}

class MapItem {
  final String id;
  final String path;
  final String name;

  MapItem({required this.id, required this.path, required this.name});

  factory MapItem.fromJson(Map<String, dynamic> json) {
    return MapItem(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'path': path, 'name': name};
  }
}

class VirtualPath {
  final String id;
  final int version;
  final String? author;
  final String name;
  final String? description;
  final List<PathPoint> points;

  VirtualPath({
    required this.id,
    required this.version,
    this.author,
    required this.name,
    this.description,
    required this.points,
  });

  factory VirtualPath.fromJson(Map<String, dynamic> json) {
    return VirtualPath(
      id: json['id'] as String,
      version: json['version'] as int,
      author: json['author'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      points: (json['points'] as List)
          .map((item) => PathPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      if (author != null) 'author': author,
      'name': name,
      if (description != null) 'description': description,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}

class PathPoint {
  final double lat;
  final double lng;
  final double? alt;

  PathPoint({required this.lat, required this.lng, this.alt});

  factory PathPoint.fromJson(Map<String, dynamic> json) {
    return PathPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      alt: json['alt'] != null ? (json['alt'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng, if (alt != null) 'alt': alt};
  }
}

class MotionProfile {
  final String id;
  final int version;
  final String? author;
  final String name;
  final String? description;
  final List<String>? repo;
  final ProfileData data;

  MotionProfile({
    required this.id,
    required this.version,
    this.author,
    required this.name,
    this.description,
    this.repo,
    required this.data,
  });

  factory MotionProfile.fromJson(Map<String, dynamic> json) {
    return MotionProfile(
      id: json['id'] as String,
      version: json['version'] as int,
      author: json['author'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      repo: json['repo'] != null
          ? (json['repo'] as List).map((item) => item as String).toList()
          : null,
      data: ProfileData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      if (author != null) 'author': author,
      'name': name,
      if (description != null) 'description': description,
      if (repo != null) 'repo': repo,
      'data': data.toJson(),
    };
  }
}

class ProfileData {
  final List<String> paths;
  final Map<String, dynamic>? ext;

  ProfileData({required this.paths, this.ext});

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      paths: (json['paths'] as List).map((item) => item as String).toList(),
      ext: json['ext'] != null
          ? Map<String, dynamic>.from(json['ext'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'paths': paths, if (ext != null) 'ext': ext};
  }
}
