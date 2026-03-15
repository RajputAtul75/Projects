import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local push notification service
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification channels
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);
  }

  /// Show a heat alert notification
  Future<void> showHeatAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'heat_alerts',
      'Heat Alerts',
      channelDescription: 'Notifications for heat risk alerts',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFE53935),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details,
        payload: payload);
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) => _notificationsPlugin.cancel(id);

  /// Cancel all notifications
  Future<void> cancelAll() => _notificationsPlugin.cancelAll();
}
