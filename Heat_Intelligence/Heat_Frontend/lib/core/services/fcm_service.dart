import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'notification_service.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // Use 10.0.2.2 for Android emulator to access local backend, or actual IP for device.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
    ),
  );

  Future<void> init() async {
    // Request permission
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('FCM: User declined or has not accepted permission');
      return;
    }

    debugPrint('FCM: User granted notification permission');

    // Get FCM token and register with backend
    final String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _registerTokenWithBackend(token);
    }

    // Refresh token listener
    _messaging.onTokenRefresh.listen(_registerTokenWithBackend);

    // ── Foreground message handler ──────────────────────────────────────────
    // When the app is open, FCM does NOT auto-show a system notification on
    // Android. We use flutter_local_notifications to display it ourselves.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Foreground message received — ${message.messageId}');
      debugPrint('FCM data: ${message.data}');

      final notification = message.notification;
      if (notification != null) {
        debugPrint('FCM notification: ${notification.title}');
        // Show a local notification so the user sees it while using the app
        NotificationService().showHeatAlert(
          id: message.hashCode,
          title: notification.title ?? 'Heat Alert',
          body: notification.body ?? '',
          payload: message.data['alert_id'],
        );
      }
    });

    // ── Background-tap handler ──────────────────────────────────────────────
    // Called when the user taps a notification and the app was in the background
    // (but not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Notification tapped (background) — ${message.messageId}');
      _handleNotificationTap(message);
    });

    // ── Terminated-state tap handler ───────────────────────────────────────
    // Called once when the app is launched by tapping a notification.
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM: App launched via notification — ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Route the user based on notification tap data.
  void _handleNotificationTap(RemoteMessage message) {
    final String? type = message.data['type'];
    debugPrint('FCM tap: type=$type, data=${message.data}');
    // TODO: Use a navigator key or go_router to navigate to the alerts screen.
    // Example: navigatorKey.currentState?.pushNamed('/alerts');
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      double lat = 0.0;
      double lng = 0.0;

      // Try to get current location
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        final LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }

      await _dio.post(
        '/api/notifications/register',
        data: {
          'fcm_token': token,
          'latitude': lat,
          'longitude': lng,
        },
      );
      debugPrint('FCM: Token registered with backend');
    } catch (e) {
      debugPrint('FCM: Failed to register token — $e');
    }
  }
}
