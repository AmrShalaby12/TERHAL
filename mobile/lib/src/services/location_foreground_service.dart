/// LocationForegroundService
///
/// A real Android foreground service (persistent notification) that keeps
/// streaming the bus GPS position to the backend every few seconds for the
/// whole trip — even if the supervisor locks the screen or switches apps.
///
/// Architecture
/// ------------
/// flutter_foreground_task runs [LocationTaskHandler] in a dedicated background
/// isolate. The isolate reads GPS (geolocator) and POSTs it straight to
/// `<baseUrl>/tracking/update/` (dio) on a fixed interval. The trip id, JWT
/// and base URL are handed to the isolate through FlutterForegroundTask's
/// persistent store before the service starts.
///
/// Public surface is just [start] / [stop] / [isRunning] — call [init] once at
/// app boot (done from main.dart).
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

const _kTripKey = 'terhal_fg_trip_id';
const _kTokenKey = 'terhal_fg_token';
const _kBaseKey = 'terhal_fg_base_url';
const _kModeKey = 'terhal_fg_mode';
const _kAllenLocationTokenKey = 'allen_driver_fg_location_token';
const _kAllenBaseUrlKey = 'allen_driver_fg_base_url';
const _kAllenBusKey = 'allen_driver_fg_bus_id';

class LocationForegroundService {
  const LocationForegroundService();

  /// Configure the foreground service. Idempotent; call once at startup.
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'terhal_location',
        channelName: 'مشاركة موقع الرحلة',
        channelDescription: 'يتم بث موقع الحافلة لأولياء الأمور أثناء الرحلة',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  /// Starts (or restarts) the persistent GPS stream for [tripId].
  Future<bool> start({
    required int tripId,
    required String token,
    required String baseUrl,
    String tripLabel = '',
  }) async {
    await FlutterForegroundTask.saveData(key: _kModeKey, value: 'terhal');
    await FlutterForegroundTask.saveData(key: _kTripKey, value: tripId);
    await FlutterForegroundTask.saveData(key: _kTokenKey, value: token);
    await FlutterForegroundTask.saveData(key: _kBaseKey, value: baseUrl);

    final title = 'ترحال — مشاركة موقع الرحلة';
    final text = tripLabel.isEmpty
        ? 'جارٍ إرسال موقع الحافلة لأولياء الأمور'
        : 'رحلة $tripLabel — الموقع يُشارَك الآن';

    final running = await FlutterForegroundTask.isRunningService;
    final result = running
        ? await FlutterForegroundTask.restartService()
        : await FlutterForegroundTask.startService(
            notificationTitle: title,
            notificationText: text,
            callback: startCallback,
          );
    return result is ServiceRequestSuccess;
  }

  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

/// Native continuation for the Allen driver WebView.
///
/// The website first authenticates the driver and issues a short-lived opaque
/// token. This service then posts directly to Allen while Android keeps the
/// foreground notification alive, so the WebView itself no longer needs to be
/// open. The backend invalidates the token after two hours.
class AllenDriverLocationService {
  const AllenDriverLocationService();

  Future<bool> start({
    required int busId,
    required String locationToken,
    required String baseUrl,
  }) async {
    if (!await _canReadLocation()) return false;

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');
    await FlutterForegroundTask.saveData(key: _kModeKey, value: 'allen_driver');
    await FlutterForegroundTask.saveData(key: _kAllenBusKey, value: busId);
    await FlutterForegroundTask.saveData(
      key: _kAllenLocationTokenKey,
      value: locationToken,
    );
    await FlutterForegroundTask.saveData(
      key: _kAllenBaseUrlKey,
      value: normalizedBaseUrl,
    );

    final running = await FlutterForegroundTask.isRunningService;
    final result = running
        ? await FlutterForegroundTask.restartService()
        : await FlutterForegroundTask.startService(
            notificationTitle: 'Allen Travel - مشاركة الموقع',
            notificationText: 'موقع الباص يُحدَّث للركاب الآن',
            callback: startCallback,
          );
    return result is ServiceRequestSuccess;
  }

  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<bool> _canReadLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

// ── Background isolate entry point ───────────────────────────────────────────

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  final Dio _dio = Dio();
  String _mode = 'terhal';
  int _tripId = 0;
  String _token = '';
  String _baseUrl = '';
  String _allenLocationToken = '';
  String _allenBaseUrl = '';

  static String _s(Object? v) => v == null ? '' : '$v';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _mode = _s(FlutterForegroundTask.getData(key: _kModeKey));
    _tripId =
        int.tryParse(_s(FlutterForegroundTask.getData(key: _kTripKey))) ?? 0;
    _token = _s(FlutterForegroundTask.getData(key: _kTokenKey));
    _baseUrl = _s(FlutterForegroundTask.getData(key: _kBaseKey));
    _allenLocationToken =
        _s(FlutterForegroundTask.getData(key: _kAllenLocationTokenKey));
    _allenBaseUrl = _s(FlutterForegroundTask.getData(key: _kAllenBaseUrlKey));
    await _pushOnce();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) => _pushOnce();

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  Future<void> _pushOnce() async {
    if (_mode == 'allen_driver') {
      await _pushAllenLocation();
      return;
    }
    if (_tripId == 0 || _token.isEmpty || _baseUrl.isEmpty) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final speedKmh = pos.speed > 0 ? (pos.speed * 3.6).round() : 0;
      final heading = pos.heading >= 0 ? pos.heading.round() : 0;
      await _dio.post(
        '$_baseUrl/tracking/update/',
        data: {
          'trip_id': _tripId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'speed_kmh': speedKmh,
          'heading': heading,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      FlutterForegroundTask.updateService(
        notificationTitle: 'ترحال — الموقع يُشارَك',
        notificationText: 'آخر تحديث $hh:$mm',
      );
    } catch (e) {
      debugPrint('LocationTaskHandler push failed: $e');
    }
  }

  Future<void> _pushAllenLocation() async {
    if (_allenLocationToken.isEmpty || _allenBaseUrl.isEmpty) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await _dio.post(
        '$_allenBaseUrl/allen/api/mobile/driver/location/update/',
        data: {
          'location_token': _allenLocationToken,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
        options: Options(
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      FlutterForegroundTask.updateService(
        notificationTitle: 'Allen Travel - الموقع يُشارَك',
        notificationText: 'آخر تحديث $hh:$mm',
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        await FlutterForegroundTask.stopService();
        return;
      }
      debugPrint('Allen driver location push failed: $error');
    } catch (error) {
      debugPrint('Allen driver location push failed: $error');
    }
  }
}
