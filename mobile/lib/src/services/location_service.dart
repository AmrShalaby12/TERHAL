/// LocationSharingService
///
/// Used by the supervisor app to continuously broadcast the bus GPS position
/// to the backend every [intervalSeconds] seconds while a trip is active.
///
/// Lifecycle:
///   1. Call [start] when the supervisor begins a trip.
///   2. The service requests location permission if needed.
///   3. A periodic timer fires every 5 s, reads GPS, POSTs to backend.
///   4. Call [stop] when the trip ends or the screen is disposed.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

typedef LocationCallback = Future<void> Function({
  required double latitude,
  required double longitude,
  required int speedKmh,
  required int heading,
});

class LocationSharingService {
  LocationSharingService({
    this.intervalSeconds = 5,
    required this.onLocation,
    this.onError,
  });

  final int intervalSeconds;
  final LocationCallback onLocation;
  final void Function(String message)? onError;

  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  /// Requests permissions and starts the periodic GPS → backend loop.
  Future<bool> start() async {
    if (_running) return true;

    final ok = await _ensurePermission();
    if (!ok) {
      onError?.call('تعذّر الحصول على إذن الموقع. يرجى السماح للتطبيق بالوصول إلى GPS.');
      return false;
    }

    _running = true;
    // Immediately push once, then on every interval tick.
    await _push();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => _push());
    return true;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Future<void> _push() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final speedKmh = pos.speed > 0 ? (pos.speed * 3.6).round() : 0;
      final heading = pos.heading >= 0 ? pos.heading.round() : 0;
      await onLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: speedKmh,
        heading: heading,
      );
    } catch (e) {
      onError?.call('خطأ في قراءة GPS: $e');
    }
  }

  static Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
