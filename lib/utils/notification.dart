import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();
final LinuxInitializationSettings initializationSettingsLinux =
    LinuxInitializationSettings(defaultActionName: 'Open notification');
final WindowsInitializationSettings initializationSettingsWindows =
    WindowsInitializationSettings(
      appName: 'Punklorde',
      appUserModelId: 'Hacker.SilverWolf.Punklorde',
      guid: '025abcf6-b034-0ab5-4301-a5cf30e60f65',
    );
final InitializationSettings initializationSettings = InitializationSettings(
  android: initializationSettingsAndroid,
  iOS: initializationSettingsDarwin,
  macOS: initializationSettingsDarwin,
  linux: initializationSettingsLinux,
  windows: initializationSettingsWindows,
);

void initNoticationPlugin() {
  notificationsPlugin.initialize(settings: initializationSettings);
}

Future<void> showNotification(
  String title,
  String body, {
  int id = 0,
  String channelId = "main_channel",
  String channelName = "Main Channel",
  String? payload,
  int importance = 2,
}) async {
  await notificationsPlugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelName,
        importance: switch (importance) {
          0 => .min,
          1 => .low,
          2 => .defaultImportance,
          3 => .high,
          4 => .max,
          _ => .defaultImportance,
        },
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: payload,
  );
}
