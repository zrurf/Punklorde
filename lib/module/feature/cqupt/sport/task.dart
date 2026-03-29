import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// 初始化前台服务
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'punklorde_feat_sport_cqupt',
      channelName: 'Punklorde CQUPT Sport Service',
      channelDescription: 'This notification keeps the running service alive.',
      channelImportance: .HIGH,
      priority: .HIGH,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true, // iOS 上是否显示通知
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: false, // 是否开机自启
      allowWakeLock: true, // 保持屏幕唤醒
      allowWifiLock: true, // 保持WiFi连接
      eventAction: ForegroundTaskEventAction.repeat(1000),
    ),
  );
}
