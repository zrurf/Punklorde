/// 资源源定义
class Source {
  final String id;
  final String baseUrl;
  final int priority; // 优先级，数字越小优先级越高
  final bool enabled;

  Source({
    required this.id,
    required this.baseUrl,
    this.priority = 0,
    this.enabled = true,
  });
}

/// 资源状态
enum ResourceStatus { initial, loading, localLoaded, remoteLoaded, error }

class ResourceState {
  final ResourceStatus status;
  final String? localPath; // 本地缓存路径
  final String? error;
  final double progress; // 下载进度 0.0 - 1.0

  ResourceState({
    this.status = ResourceStatus.initial,
    this.localPath,
    this.error,
    this.progress = 0.0,
  });

  ResourceState copyWith({
    ResourceStatus? status,
    String? localPath,
    String? error,
    double? progress,
  }) {
    return ResourceState(
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}
