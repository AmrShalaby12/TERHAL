import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'location_foreground_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Starts native services without holding the first Flutter frame hostage.
///
/// Every consumer awaits the same memoized future, so push setup can safely run
/// after the UI is already visible without initializing Firebase twice.
class PlatformBootstrap {
  PlatformBootstrap._();

  static Future<void>? _initialization;

  static bool get isSupported {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  static Future<void> ensureInitialized() {
    if (!isSupported) return Future<void>.value();
    return _initialization ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    } catch (error) {
      debugPrint('Firebase initialization is unavailable: $error');
    }

    FlutterForegroundTask.initCommunicationPort();
    LocationForegroundService.init();
  }
}
