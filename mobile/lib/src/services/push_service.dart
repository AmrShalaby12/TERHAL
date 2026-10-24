/// PushService
///
/// Owns the device side of "notifications for all devices":
///   1. Creates the high-importance Android channel that matches the backend
///      (channel id `terhal_high_importance`).
///   2. Asks for notification permission (Android 13+).
///   3. Boots Firebase Messaging, returns the FCM token, and listens for token
///      refreshes so the backend always has a live token.
///   4. While the app is in the foreground, FCM does NOT show a tray
///      notification — we render it ourselves via flutter_local_notifications
///      so the user always sees it.
///   5. Surfaces notification taps (foreground, background, terminated) through
///      a single [onOpen] callback carrying the data payload, so the app can
///      deep-link (open tracking, return-trip sheet, …).
///
/// The top-level background isolate handler lives in main.dart (FCM requirement).
library;

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef PushOpenCallback = void Function(Map<String, dynamic> data);

const AndroidNotificationChannel kTerhalChannel = AndroidNotificationChannel(
  'allen_travel_alerts',
  'تنبيهات Allen Travel',
  description: 'إشعارات الحضور وتتبع الرحلة والمدفوعات',
  importance: Importance.high,
);

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;
  PushOpenCallback? _onOpen;

  /// One-time wiring. Safe to call again (no-ops after the first run).
  /// Returns the FCM token (or null if unavailable / permission denied).
  Future<String?> setUp({required PushOpenCallback onOpen}) async {
    _onOpen = onOpen;

    if (!_initialised) {
      await _initLocalNotifications();
      await _createChannel();
      _initialised = true;
    }

    // Ask the OS for permission (Android 13+/iOS). permission_handler also
    // covers this; requesting here keeps FCM's own state in sync.
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages → render locally so they're never silently dropped.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // App opened from background by tapping the tray notification.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _dispatchOpen(m.data));

    // App launched from terminated state by tapping the tray notification.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _dispatchOpen(initial.data);

    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('PushService: getToken failed: $e');
      return null;
    }
  }

  /// Fires whenever FCM rotates the token; keep the backend updated.
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _dispatchOpen((jsonDecode(payload) as Map).cast<String, dynamic>());
        } catch (_) {
          /* malformed payload — ignore */
        }
      },
    );
  }

  Future<void> _createChannel() async {
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(kTerhalChannel);
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString() ?? 'ترحال';
    final body = n?.body ?? message.data['body']?.toString() ?? '';
    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kTerhalChannel.id,
          kTerhalChannel.name,
          channelDescription: kTerhalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _dispatchOpen(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    _onOpen?.call(data);
  }
}
