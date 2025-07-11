import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);
  }

  static Future<void> showIncomingCallNotification(String caller) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Call',
      channelDescription: 'Channel for incoming call notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      ongoing: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      100, // notification id
      'Panggilan Masuk',
      caller,
      notificationDetails,
      payload: 'incoming_call',
    );
  }

  static Future<void> cancelIncomingCallNotification() async {
    await _plugin.cancel(100);
  }
}
