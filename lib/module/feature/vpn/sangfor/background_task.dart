import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Initialize foreground task for VPN keep-alive
void initVpnForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'punklorde_vpn_sangfor',
      channelName: 'Punklorde SSL VPN',
      channelDescription: 'Keeps the VPN tunnel alive in the background.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
      eventAction: ForegroundTaskEventAction.nothing(),
    ),
  );
}

/// Start VPN foreground service
Future<void> startVpnForegroundService() async {
  if (await FlutterForegroundTask.isRunningService) return;

  await FlutterForegroundTask.startService(
    notificationTitle: 'SSL VPN Connected',
    notificationText: 'VPN tunnel is active',
    notificationButtons: [
      const NotificationButton(id: 'btn_disconnect', text: 'Disconnect'),
    ],
    callback: _onForegroundTaskStart,
  );
}

/// Stop VPN foreground service
Future<void> stopVpnForegroundService() async {
  await FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
void _onForegroundTaskStart() {
  FlutterForegroundTask.setTaskHandler(VpnTaskHandler());
}

class VpnTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_disconnect') {
      // Disconnect handled by main isolate
    }
  }
}
