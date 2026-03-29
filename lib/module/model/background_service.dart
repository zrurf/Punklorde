/// 后台轮询服务
abstract class BackgroundPollingTask {
  String get id;
  String get name;

  int get intervalMs;

  Future<void> init();
  Future<void> dispose();
  Future<void> onInvoke();
}
