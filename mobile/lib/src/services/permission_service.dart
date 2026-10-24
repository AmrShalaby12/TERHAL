/// PermissionService
///
/// One place that owns every runtime permission the app needs:
///   • Camera      — supervisor QR attendance scan
///   • Location     — supervisor live GPS sharing (+ background while a trip runs)
///   • Notifications — FCM / local notifications (Android 13+)
///
/// Every method returns a [PermissionOutcome] so the UI can react precisely:
/// granted → proceed, denied → show rationale + retry, permanentlyDenied →
/// guide the user to app settings. Nothing here throws.
library;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionOutcome {
  granted,

  /// Temporarily denied — asking again is allowed.
  denied,

  /// "Don't ask again" / restricted — must open app settings.
  permanentlyDenied,

  /// A required OS service is off (e.g. GPS turned off on the device).
  serviceDisabled,
}

class PermissionService {
  const PermissionService();

  bool isUsable(PermissionOutcome o) => o == PermissionOutcome.granted;

  /// Opens the system app-settings page (used after a permanent denial).
  Future<bool> openSettings() => openAppSettings();

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<PermissionOutcome> ensureCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    final result = await Permission.camera.request();
    return _map(result);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Android 13+ requires an explicit POST_NOTIFICATIONS grant. On older
  /// Android / web this resolves to granted automatically.
  Future<PermissionOutcome> ensureNotifications() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) {
      return PermissionOutcome.permanentlyDenied;
    }
    final result = await Permission.notification.request();
    return _map(result);
  }

  // ── Location ──────────────────────────────────────────────────────────────

  /// Foreground (while-in-use) location — enough to start GPS sharing while
  /// the supervisor app is open.
  Future<PermissionOutcome> ensureLocationWhenInUse() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PermissionOutcome.serviceDisabled;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return PermissionOutcome.permanentlyDenied;
    }
    if (perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always) {
      return PermissionOutcome.granted;
    }
    return PermissionOutcome.denied;
  }

  /// Background location ("Allow all the time"). Requested only after
  /// while-in-use is already granted — Android mandates that order. A denial
  /// here is non-fatal: the foreground service still streams while the
  /// notification is visible, so we surface it but let the caller continue.
  Future<PermissionOutcome> ensureLocationBackground() async {
    final whenInUse = await ensureLocationWhenInUse();
    if (whenInUse != PermissionOutcome.granted) return whenInUse;

    final status = await Permission.locationAlways.status;
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) {
      return PermissionOutcome.permanentlyDenied;
    }
    final result = await Permission.locationAlways.request();
    return _map(result);
  }

  PermissionOutcome _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return PermissionOutcome.granted;
    if (s.isPermanentlyDenied || s.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    return PermissionOutcome.denied;
  }
}

const permissionService = PermissionService();
