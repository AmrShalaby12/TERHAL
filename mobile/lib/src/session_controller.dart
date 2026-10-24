import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'models.dart';
import 'services/location_foreground_service.dart';

const _kAccessKey = 'terhal_access_token';
const _kRefreshKey = 'terhal_refresh_token';
const _kUserKey = 'terhal_user_json';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final sessionProvider = StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(ref.read(apiServiceProvider)),
);

class SessionState {
  const SessionState({
    this.isLoading = false,
    this.errorMessage,
    this.auth,
    this.studentHome,
    this.supervisorOverview,
    this.trips = const [],
    this.bookings = const [],
    this.notifications = const [],
    this.payments = const [],
    this.paymentsLoaded = false,
    this.paymentsError,
    this.parentTracking = const [],
    this.parentSummary,
    this.appExperience = const AppExperienceModel(),
  });

  final bool isLoading;
  final String? errorMessage;
  final AuthPayload? auth;
  final StudentHomeModel? studentHome;
  final SupervisorOverviewModel? supervisorOverview;
  final List<TripModel> trips;
  final List<BookingModel> bookings;
  final List<NotificationModel> notifications;
  final List<PaymentModel> payments;
  final bool paymentsLoaded;
  final String? paymentsError;
  final List<LocationShareModel> parentTracking;
  final ParentSummaryModel? parentSummary;
  final AppExperienceModel appExperience;

  bool get isAuthenticated => auth != null;
  UserProfile? get user => auth?.user;
  String get token => auth?.accessToken ?? '';

  SessionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AuthPayload? auth,
    bool clearAuth = false,
    StudentHomeModel? studentHome,
    SupervisorOverviewModel? supervisorOverview,
    List<TripModel>? trips,
    List<BookingModel>? bookings,
    List<NotificationModel>? notifications,
    List<PaymentModel>? payments,
    bool? paymentsLoaded,
    String? paymentsError,
    bool clearPaymentsError = false,
    List<LocationShareModel>? parentTracking,
    ParentSummaryModel? parentSummary,
    AppExperienceModel? appExperience,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      auth: clearAuth ? null : auth ?? this.auth,
      studentHome: studentHome ?? this.studentHome,
      supervisorOverview: supervisorOverview ?? this.supervisorOverview,
      trips: trips ?? this.trips,
      bookings: bookings ?? this.bookings,
      notifications: notifications ?? this.notifications,
      payments: payments ?? this.payments,
      paymentsLoaded: paymentsLoaded ?? this.paymentsLoaded,
      paymentsError: clearPaymentsError
          ? null
          : paymentsError ?? this.paymentsError,
      parentTracking: parentTracking ?? this.parentTracking,
      parentSummary: parentSummary ?? this.parentSummary,
      appExperience: appExperience ?? this.appExperience,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._api, {bool restoreSession = true})
    : super(const SessionState(isLoading: true)) {
    if (restoreSession) unawaited(bootstrap());
  }

  final ApiService _api;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  /// Last FCM token handed to us by PushService — kept so logout can
  /// deactivate it server-side and the foreground isolate is never orphaned.
  String? _fcmToken;
  final LocationForegroundService _liveLocation =
      const LocationForegroundService();

  bool get _foregroundServiceSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Called by the UI once the FCM token is known (and on every refresh).
  /// Idempotent — backend upserts by token.
  Future<void> bindDevice(String fcmToken) async {
    _fcmToken = fcmToken;
    final token = state.token;
    if (token.isEmpty) return;
    try {
      await _api.registerDevice(token: token, fcmToken: fcmToken);
    } catch (_) {
      // Token binding is best-effort; in-app notifications still work.
    }
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final auth = await _api.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      state = state.copyWith(isLoading: false, auth: auth);
      await _persist(auth);
      await refresh();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String role,
    String faculty = '',
    String academicYear = '',
    String universityCode = '',
    String universityName = '',
    String studentCode = '',
    String studentPhoneNumber = '',
    String relation = '',
    String guardianPhone = '',
    int? routeId,
    int? pickupStopId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final auth = await _api.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
        faculty: faculty,
        academicYear: academicYear,
        universityCode: universityCode,
        universityName: universityName,
        studentCode: studentCode,
        studentPhoneNumber: studentPhoneNumber,
        relation: relation,
        guardianPhone: guardianPhone,
        routeId: routeId,
        pickupStopId: pickupStopId,
      );
      state = state.copyWith(isLoading: false, auth: auth);
      await _persist(auth);
      await refresh();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── Persistent session ────────────────────────────────────────────────────

  Future<void> _persist(AuthPayload auth) async {
    await Future.wait([
      _secureStorage.write(key: _kAccessKey, value: auth.accessToken),
      _secureStorage.write(key: _kRefreshKey, value: auth.refreshToken),
      _secureStorage.write(
        key: _kUserKey,
        value: jsonEncode(auth.user.toJson()),
      ),
    ]);
  }

  Future<void> _clearPersist() async {
    await Future.wait([
      _secureStorage.delete(key: _kAccessKey),
      _secureStorage.delete(key: _kRefreshKey),
      _secureStorage.delete(key: _kUserKey),
    ]);
  }

  /// Restores a saved session on app start so the user logs in **only once**.
  ///
  /// Offline-first: the stored user is restored immediately without any
  /// network call, so a closed server / dropped Wi-Fi never logs the user
  /// out. We only force a re-login when the backend explicitly rejects the
  /// credentials (token refresh returns invalid), never on a network error.
  Future<void> bootstrap() async {
    var access = '';
    var refreshToken = '';
    var userJson = '';
    try {
      access = await _secureStorage.read(key: _kAccessKey) ?? '';
      refreshToken = await _secureStorage.read(key: _kRefreshKey) ?? '';
      userJson = await _secureStorage.read(key: _kUserKey) ?? '';
    } catch (_) {
      // A rotated browser encryption key or an interrupted OS keychain
      // migration must never strand the app on its splash screen.
      try {
        await _secureStorage.deleteAll();
      } catch (_) {
        // Continue to the legacy migration / signed-out state below.
      }
    }

    // One-time migration from the development builds that stored JWTs in
    // SharedPreferences. Device identifiers remain there intentionally; auth
    // tokens and the cached profile move to encrypted platform storage.
    if (access.isEmpty || userJson.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      access = prefs.getString(_kAccessKey) ?? '';
      refreshToken = prefs.getString(_kRefreshKey) ?? '';
      userJson = prefs.getString(_kUserKey) ?? '';
      if (access.isNotEmpty && userJson.isNotEmpty) {
        try {
          await Future.wait([
            _secureStorage.write(key: _kAccessKey, value: access),
            _secureStorage.write(key: _kRefreshKey, value: refreshToken),
            _secureStorage.write(key: _kUserKey, value: userJson),
          ]);
          await Future.wait([
            prefs.remove(_kAccessKey),
            prefs.remove(_kRefreshKey),
            prefs.remove(_kUserKey),
          ]);
        } catch (_) {
          // Keep the legacy values for a later migration attempt. The cached
          // session can still be restored for this launch.
        }
      }
    }

    if (access.isEmpty || userJson.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    UserProfile user;
    try {
      user = UserProfile.fromJson(
        (jsonDecode(userJson) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      await _clearPersist();
      state = state.copyWith(isLoading: false);
      return;
    }

    // Restore the session straight away (no network needed) so the splash
    // never waits on connectivity.
    state = state.copyWith(
      isLoading: false,
      auth: AuthPayload(
        user: user,
        accessToken: access,
        refreshToken: refreshToken,
      ),
    );

    // Fire the data sync in the background — do NOT block app start on it.
    unawaited(_postRestoreSync(user, access, refreshToken));
  }

  /// Best-effort sync after an offline restore. Transparently refreshes an
  /// expired access token. Network failures are swallowed — the user stays
  /// logged in (only an explicit logout clears the saved session).
  Future<void> _postRestoreSync(
    UserProfile user,
    String access,
    String refreshToken,
  ) async {
    try {
      final freshUser = await _api.me(access);
      if (state.token == access) {
        state = state.copyWith(
          auth: AuthPayload(
            user: freshUser,
            accessToken: access,
            refreshToken: refreshToken,
          ),
        );
        await _persist(state.auth!);
      }
    } catch (_) {
      if (refreshToken.isNotEmpty) {
        final refreshed = await _api.refreshTokens(refreshToken);
        if (refreshed != null) {
          state = state.copyWith(
            auth: AuthPayload(
              user: user,
              accessToken: refreshed.access,
              refreshToken: refreshed.refresh,
            ),
          );
          await _persist(state.auth!);
        }
      }
    }
    await refresh();
  }

  Future<void> refresh({bool retryAuthentication = true}) async {
    final user = state.user;
    final token = state.token;
    if (user == null || token.isEmpty) {
      return;
    }
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      if (user.isStudent) {
        // Profile and invoices must not depend on trips/notifications working.
        await Future.wait([
          _refreshStudentProfile(token),
          _refreshPayments(token),
          _refreshAppExperience(),
        ]);
        final (home, trips, bookings, notifications) = await (
          _api.fetchStudentHome(token),
          _api.fetchTrips(token),
          _api.fetchBookings(token),
          _api.fetchNotifications(token),
        ).wait;
        _alertForNewNotifications(state.notifications, notifications);
        state = state.copyWith(
          isLoading: false,
          studentHome: home,
          trips: trips,
          bookings: bookings,
          notifications: notifications,
        );
      } else if (user.isSupervisor) {
        final failures = <String>[];
        Future<void> loadSection(
          String label,
          Future<void> Function() load,
        ) async {
          try {
            await load();
          } catch (error) {
            if (_isUnauthorized(error)) rethrow;
            failures.add(label);
          }
        }

        await Future.wait([
          loadSection('الإحصائيات', () async {
            final value = await _api.fetchSupervisorOverview(token);
            if (state.token == token) {
              state = state.copyWith(supervisorOverview: value);
            }
          }),
          loadSection('الرحلات', () async {
            final value = await _api.fetchTrips(token);
            if (state.token == token) state = state.copyWith(trips: value);
          }),
          loadSection('الحجوزات', () async {
            final value = await _api.fetchBookings(token);
            if (state.token == token) state = state.copyWith(bookings: value);
          }),
          loadSection('الإشعارات', () async {
            final value = await _api.fetchNotifications(token);
            if (state.token == token) {
              _alertForNewNotifications(state.notifications, value);
              state = state.copyWith(notifications: value);
            }
          }),
        ]);
        if (state.token == token) {
          state = state.copyWith(
            isLoading: false,
            clearError: failures.isEmpty,
            errorMessage: failures.isEmpty
                ? null
                : 'تعذر تحديث ${failures.join('، ')}. اسحب للتحديث؛ البيانات السابقة محفوظة.',
          );
        }
      } else if (user.isParent) {
        final (notifications, tracking, parentSummary) = await (
          _api.fetchNotifications(token),
          _api.fetchParentTracking(token),
          _api.fetchParentSummary(token),
        ).wait;
        _alertForNewNotifications(state.notifications, notifications);
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          parentTracking: tracking,
          parentSummary: parentSummary,
        );
      } else {
        final notifications = await _api.fetchNotifications(token);
        _alertForNewNotifications(state.notifications, notifications);
        state = state.copyWith(isLoading: false, notifications: notifications);
      }
    } catch (error) {
      if (retryAuthentication &&
          _isUnauthorized(error) &&
          await _renewAccessToken()) {
        await refresh(retryAuthentication: false);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _refreshStudentProfile(String token) async {
    try {
      final freshUser = await _api.me(token);
      if (state.token != token || state.auth == null) return;
      state = state.copyWith(
        auth: AuthPayload(
          user: freshUser,
          accessToken: token,
          refreshToken: state.auth!.refreshToken,
        ),
      );
      await _persist(state.auth!);
    } catch (error) {
      if (_isUnauthorized(error)) rethrow;
      // Preserve the last profile when offline; other requests still proceed.
    }
  }

  Future<void> _refreshPayments(String token) async {
    try {
      final payments = await _api.fetchPayments(token);
      if (state.token != token) return;
      state = state.copyWith(
        payments: payments,
        paymentsLoaded: true,
        clearPaymentsError: true,
      );
    } catch (error) {
      if (state.token != token) return;
      state = state.copyWith(
        paymentsError:
            'تعذر تحديث الفواتير. تحقق من الاتصال واسحب الصفحة للتحديث.',
      );
      if (_isUnauthorized(error)) rethrow;
    }
  }

  Future<void> _refreshAppExperience() async {
    try {
      final experience = await _api.fetchAppExperience();
      state = state.copyWith(appExperience: experience);
    } catch (_) {
      // Presentation copy keeps its bundled defaults while offline.
    }
  }

  Future<void> updateStudentProfile({
    required String universityCode,
    required int routeId,
    required int pickupStopId,
    required String faculty,
  }) async {
    final user = await _authenticated(
      (token) => _api.updateStudentProfile(
        token: token,
        universityCode: universityCode,
        routeId: routeId,
        pickupStopId: pickupStopId,
        faculty: faculty,
      ),
    );
    if (state.auth != null) {
      state = state.copyWith(
        auth: AuthPayload(
          user: user,
          accessToken: state.auth!.accessToken,
          refreshToken: state.auth!.refreshToken,
        ),
      );
      await _persist(state.auth!);
    }
    await refresh();
  }

  Future<void> bookTrip(int tripId, {int? pickupStopId}) async {
    await _authenticated(
      (token) => _api.bookTrip(token, tripId, pickupStopId: pickupStopId),
    );
    await refresh();
  }

  Future<int> sendSupervisorMessage({
    required String target,
    int? tripId,
    required String title,
    required String body,
    String? date,
    String? timeFrom,
    String? timeTo,
    String? direction,
  }) async {
    final count = await _authenticated(
      (token) => _api.sendSupervisorMessage(
        token: token,
        target: target,
        tripId: tripId,
        title: title,
        body: body,
        date: date,
        timeFrom: timeFrom,
        timeTo: timeTo,
        direction: direction,
      ),
    );
    await refresh();
    return count;
  }

  Future<void> requestSubscription({
    String planName = 'اشتراك شهري',
    int durationDays = 30,
    int totalRides = 44,
  }) async {
    await _authenticated(
      (token) => _api.requestSubscription(
        token: token,
        planName: planName,
        durationDays: durationDays,
        totalRides: totalRides,
      ),
    );
    await refresh();
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _authenticated(
      (token) => _api.markNotificationRead(token, notificationId),
    );
    final updated = state.notifications
        .map(
          (item) => item.id == notificationId
              ? NotificationModel(
                  id: item.id,
                  title: item.title,
                  body: item.body,
                  type: item.type,
                  isRead: true,
                  createdAt: item.createdAt,
                  data: item.data,
                )
              : item,
        )
        .toList();
    state = state.copyWith(notifications: updated);
  }

  Future<ScanAttendanceResult> scanAttendance({
    required int tripId,
    required String qrToken,
  }) async {
    final result = await _authenticated(
      (token) =>
          _api.scanAttendance(token: token, tripId: tripId, qrToken: qrToken),
    );
    await refresh();
    return result;
  }

  /// Supervisor shares the trip location: notifies parents AND starts the
  /// persistent foreground GPS broadcast so the bus actually moves on their
  /// map (previously the share only created DB sessions with no GPS source).
  Future<int> supervisorShareTripLocation(int tripId) async {
    final count = await _authenticated(
      (token) => _api.supervisorShareTripLocation(token: token, tripId: tripId),
    );
    await startLiveLocationBroadcast(tripId);
    await refresh();
    return count;
  }

  /// Student-initiated share of their own trip with their parents.
  Future<void> shareStudentLocation(int tripId) async {
    await _authenticated(
      (token) => _api.studentShareTripLocation(token: token, tripId: tripId),
    );
    await refresh();
  }

  /// Starts the foreground service that streams GPS for [tripId] until
  /// [stopLiveLocationBroadcast] is called. No-op off Android.
  Future<bool> startLiveLocationBroadcast(int tripId) async {
    if (!_foregroundServiceSupported) return false;
    final trip = state.trips.firstWhere(
      (t) => t.id == tripId,
      orElse: () => state.trips.isEmpty
          ? throw StateError('no trips')
          : state.trips.first,
    );
    return _liveLocation.start(
      tripId: tripId,
      token: state.token,
      baseUrl: ApiService.apiBaseUrl,
      tripLabel: trip.tripCode,
    );
  }

  Future<void> stopLiveLocationBroadcast() async {
    if (!_foregroundServiceSupported) return;
    await _liveLocation.stop();
  }

  Future<TrackingPayload> trackingForTrip(int tripId) {
    return _authenticated((token) => _api.fetchTracking(token, tripId));
  }

  Future<T> _authenticated<T>(Future<T> Function(String token) request) async {
    try {
      return await request(state.token);
    } catch (error) {
      if (_isUnauthorized(error) && await _renewAccessToken()) {
        return request(state.token);
      }
      rethrow;
    }
  }

  bool _isUnauthorized(Object error) =>
      error is DioException && error.response?.statusCode == 401;

  Future<bool> _renewAccessToken() async {
    final auth = state.auth;
    if (auth == null || auth.refreshToken.isEmpty) return false;
    final refreshed = await _api.refreshTokens(auth.refreshToken);
    if (refreshed == null) return false;
    final updated = AuthPayload(
      user: auth.user,
      accessToken: refreshed.access,
      refreshToken: refreshed.refresh,
    );
    state = state.copyWith(auth: updated);
    await _persist(updated);
    return true;
  }

  Future<void> logout() async {
    final auth = state.auth;
    final token = state.token;
    final fcm = _fcmToken;
    if (token.isNotEmpty && fcm != null && fcm.isNotEmpty) {
      try {
        await _api.unregisterDevice(token: token, fcmToken: fcm);
      } catch (_) {
        // Best-effort: an offline user must still be able to sign out locally.
      }
    }
    if (auth != null && auth.refreshToken.isNotEmpty) {
      try {
        await _api.logout(
          token: auth.accessToken,
          refreshToken: auth.refreshToken,
        );
      } catch (_) {
        // Local logout must still complete while offline.
      }
    }
    await stopLiveLocationBroadcast();
    await _clearPersist();
    state = const SessionState();
  }

  void _alertForNewNotifications(
    List<NotificationModel> previous,
    List<NotificationModel> next,
  ) {
    if (previous.isEmpty || next.isEmpty) return;
    final previousIds = previous.map((item) => item.id).toSet();
    final hasNewUnread = next.any(
      (item) => !item.isRead && !previousIds.contains(item.id),
    );
    if (hasNewUnread) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
