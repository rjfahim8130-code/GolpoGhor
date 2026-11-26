// lib/core/services/push_notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  StreamSubscription? _notifSub; // ✅ মেমরি লিক ফিক্স

  Future<void> init() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      // ✅ লগইন/লগআউট ট্র্যাক করা
      Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.session != null) {
          _listenToNotifications();
        } else {
          _notifSub?.cancel();
        }
      });

    } catch (e) {
      debugPrint('PUSH_INIT_FAILED: $e');
    }
  }

  void _listenToNotifications() {
    _notifSub?.cancel(); // ✅ পুরনো স্ট্রিম বন্ধ
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _notifSub = Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
        if (data.isNotEmpty) {
          final latest = data.first;
          final isRead = latest['is_read'] as bool? ?? false;
          
          if (!isRead) {
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
