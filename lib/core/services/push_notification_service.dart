import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // ট্যাপ করলে অ্যাপের ভেতরে নোটিফিকেশন স্ক্রিনে নিয়ে যাওয়ার লজিক এখানে বসবে
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // পারমিশন চাওয়া (Android 13+)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _listenToNotifications();
    } catch (e) {
      debugPrint('PUSH_INIT_FAILED: $e');
    }
  }

  // ✅ নতুন মেথড: Supabase Realtime স্ট্রিম সাবস্ক্রাইব করা
  void _listenToNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
        if (data.isNotEmpty) {
          final latest = data.first;
          final isRead = latest['is_read'] as bool? ?? false;
          
          if (!isRead) {
            // নতুন নোটিফিকেশন এলে স্ক্রিনে ভাসাবো
            final message = latest['message'] as String? ?? 'নতুন নোটিফিকেশন';
            showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: 'গল্পঘর',
              body: message,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('REALTIME_SUBSCRIBE_FAILED: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'golpoghor_channel',
        'GolpoGhor Notifications',
        channelDescription: 'Notifications for likes, comments, follows, etc.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await _notificationsPlugin.show(id, title, body, notificationDetails);
    } catch (e) {
      debugPrint('SHOW_NOTIFICATION_FAILED: $e');
    }
  }
}
