// lib/core/services/push_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // TODO: Handle notification tap
        },
      );

      // পারমিশন চাওয়া (Android 13+)
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('PUSH_INIT_FAILED: $e');
    }
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'golpoghor_channel', 'GolpoGhor Notifications',
        channelDescription: 'Notifications for likes, comments, follows, etc.',
        importance: Importance.max, priority: Priority.high, ticker: 'ticker',
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
      await _notificationsPlugin.show(id, title, body, notificationDetails);
    } catch (e) {
      debugPrint('SHOW_NOTIFICATION_FAILED: $e');
    }
  }
}
