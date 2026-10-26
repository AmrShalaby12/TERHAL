import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

typedef RefreshedTokens = ({String access, String refresh});

class ApiService {
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          contentType: 'application/json',
        ),
      );

  final Dio _dio;

  /// Optional build-time override for running on a physical device on the
  /// same LAN as the backend, e.g.:
  ///   flutter run --dart-define=API_HOST=192.168.0.106
  /// Development builds use local endpoints; store builds default to Terhal.
  static const String _apiHostOverride = String.fromEnvironment('API_HOST');
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _baseUrl => resolveBaseUrl();

  /// Keep Xcode archives launchable without custom --dart-define arguments.
  /// Explicit environment overrides still require a valid production URL.
  @visibleForTesting
  static String resolveBaseUrl({
    bool releaseMode = kReleaseMode,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
    String apiBaseUrlOverride = _apiBaseUrlOverride,
    String apiHostOverride = _apiHostOverride,
  }) {
    if (apiBaseUrlOverride.isNotEmpty) {
      final value = apiBaseUrlOverride.replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw StateError('API_BASE_URL must be an absolute URL.');
      }
      final isLoopback = uri.host == '127.0.0.1' || uri.host == 'localhost';
      if (releaseMode && uri.scheme != 'https' && !isLoopback) {
        throw StateError('Production API_BASE_URL must use HTTPS.');
      }
      return value;
    }
    if (apiHostOverride.isNotEmpty) {
      if (releaseMode) {
        throw StateError(
          'API_HOST is development-only; use an HTTPS API_BASE_URL in production.',
        );
      }
      return 'http://$apiHostOverride:8001/api';
    }
    if (releaseMode) {
      return 'https://ter7al.noxusai.online/api';
    }
    if (isWeb) {
      return 'http://127.0.0.1:8001/api';
    }
    if ((platform ?? defaultTargetPlatform) == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api';
    }
    return 'http://127.0.0.1:8001/api';
  }

  /// Exposed so the background location isolate can POST GPS with the same
  /// host the app talks to.
  static String get apiBaseUrl => _baseUrl;

  static String absoluteMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) return parsed.toString();
    final api = Uri.parse(_baseUrl);
    return api
        .replace(
          path: trimmed.startsWith('/') ? trimmed : '/$trimmed',
          query: '',
        )
        .toString();
  }

  Future<AuthPayload> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final deviceId = await _deviceBindingId();
      final response = await _dio.post(
        '/auth/login/',
        data: {
          'phone_number': phoneNumber,
          'password': password,
          'device_id': deviceId,
        },
      );
      return AuthPayload.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  Future<AuthPayload> register({
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
      final response = await _dio.post(
        '/auth/register/',
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'password': password,
          'role': role,
          'faculty': faculty,
          'academic_year': academicYear,
          'university_code': universityCode,
          'university_name': universityName,
          'guardian_phone': guardianPhone,
          'route_id': routeId,
          'pickup_stop_id': pickupStopId,
          'student_code': studentCode,
          'student_phone_number': studentPhoneNumber,
          'relation': relation,
        },
      );
      return AuthPayload.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  /// Restores the signed-in user from a saved access token.
  Future<UserProfile> me(String token) async {
    final response = await _authed(token).get('/auth/me/');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateStudentProfile({
    required String token,
    required String universityCode,
    required int routeId,
    required int pickupStopId,
    required String faculty,
  }) async {
    final response = await _authed(token).patch(
      '/auth/me/',
      data: {
        'university_code': universityCode,
        'route_id': routeId,
        'pickup_stop_id': pickupStopId,
        'faculty': faculty,
      },
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppExperienceModel> fetchAppExperience() async {
    final response = await _dio.get('/app-experience/');
    return AppExperienceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<StopModel>> fetchStops() async {
    final response = await _dio.get('/stops/');
    return (response.data as List<dynamic>)
        .map(
          (item) => StopModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<RouteModel>> fetchRoutes({String? campusCode}) async {
    final response = await _dio.get(
      '/routes/',
      queryParameters: campusCode == null || campusCode.isEmpty
          ? null
          : {'campus_code': campusCode},
    );
    return (response.data as List<dynamic>)
        .map(
          (item) => RouteModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<CampusModel>> fetchCampuses() async {
    final response = await _dio.get('/campuses/');
    return (response.data as List<dynamic>)
        .map(
          (item) => CampusModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  /// Exchanges a refresh token and preserves the rotated refresh token that
  /// SimpleJWT returns in production.
  Future<RefreshedTokens?> refreshTokens(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh/',
        data: {'refresh': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final access = data['access']?.toString() ?? '';
      if (access.isEmpty) return null;
      return (
        access: access,
        refresh: data['refresh']?.toString() ?? refreshToken,
      );
    } on DioException {
      return null;
    }
  }

  Future<void> logout({
    required String token,
    required String refreshToken,
  }) async {
    await _authed(token).post('/auth/logout/', data: {'refresh': refreshToken});
  }

  Future<StudentHomeModel> fetchStudentHome(String token) async {
    final response = await _authed(token).get('/student/home/');
    return StudentHomeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TripModel>> fetchTrips(String token) async {
    final response = await _authed(token).get('/trips/');
    return (response.data as List<dynamic>)
        .map(
          (item) => TripModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<BookingModel>> fetchBookings(String token) async {
    final response = await _authed(
      token,
    ).get('/bookings/', queryParameters: {'include_history': '1'});
    return (response.data as List<dynamic>)
        .map(
          (item) =>
              BookingModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<NotificationModel>> fetchNotifications(String token) async {
    final response = await _authed(token).get('/notifications/');
    return (response.data as List<dynamic>)
        .map(
          (item) =>
              NotificationModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<PaymentModel>> fetchPayments(String token) async {
    final response = await _authed(token).get('/payments/');
    return (response.data as List<dynamic>)
        .map(
          (item) =>
              PaymentModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<SupervisorOverviewModel> fetchSupervisorOverview(String token) async {
    final response = await _authed(token).get('/supervisor/overview/');
    return SupervisorOverviewModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<TrackingPayload> fetchTracking(String token, int tripId) async {
    final response = await _authed(token).get('/tracking/$tripId/');
    return TrackingPayload.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> bookTrip(String token, int tripId, {int? pickupStopId}) async {
    await _authed(token).post(
      '/trips/book/',
      data: {'trip_id': tripId, 'pickup_stop_id': pickupStopId},
    );
  }

  Future<int> sendSupervisorMessage({
    required String token,
    required String target,
    int? tripId,
    required String title,
    required String body,
    String? date,
    String? timeFrom,
    String? timeTo,
    String? direction,
  }) async {
    final response = await _authed(token).post(
      '/supervisor/messages/',
      data: {
        'target': target,
        'trip_id': tripId,
        'title': title,
        'body': body,
        'date': date,
        'time_from': timeFrom,
        'time_to': timeTo,
        'direction': direction,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return int.tryParse(data['sent_count']?.toString() ?? '') ?? 0;
  }

  /// Called by supervisor app every ~5 s to push the current GPS position.
  /// Persists to BusLocation table + broadcasts to WebSocket subscribers.
  Future<void> pushDriverLocation({
    required String token,
    required int tripId,
    required double latitude,
    required double longitude,
    required int speedKmh,
    required int heading,
  }) async {
    await _authed(token).post(
      '/tracking/update/',
      data: {
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'heading': heading,
      },
    );
  }

  /// WebSocket URL for the live tracking consumer.
  /// Android emulator maps 10.0.2.2 to the host machine's localhost.
  static String wsTrackingUrl(int tripId, String token) {
    final apiUri = Uri.parse(_baseUrl);
    final websocketScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return apiUri
        .replace(
          scheme: websocketScheme,
          path: '/ws/tracking/$tripId/',
          queryParameters: {'token': token},
        )
        .toString();
  }

  Future<void> markNotificationRead(String token, int notificationId) async {
    await _authed(
      token,
    ).post('/notifications/', data: {'notification_id': notificationId});
  }

  Future<ScanAttendanceResult> scanAttendance({
    required String token,
    required int tripId,
    required String qrToken,
  }) async {
    try {
      final response = await _authed(token).post(
        '/attendance/scan/',
        data: {
          'trip_id': tripId,
          // Sent in both fields: the value may be a booking QR token OR the
          // student's university code — the backend resolves either.
          'qr_token': qrToken,
          'student_code': qrToken,
          'scan_type': 'board',
        },
      );
      return ScanAttendanceResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  Future<int> supervisorShareTripLocation({
    required String token,
    required int tripId,
  }) async {
    final response = await _authed(
      token,
    ).post('/supervisor/trips/$tripId/share-location/');
    final data = response.data as Map<String, dynamic>;
    return int.tryParse(data['shared_count']?.toString() ?? '') ?? 0;
  }

  /// Registers this device's FCM token so the backend can push to it.
  Future<void> registerDevice({
    required String token,
    required String fcmToken,
    String platform = 'android',
  }) async {
    final deviceId = await _deviceBindingId();
    await _authed(token).post(
      '/auth/devices/register/',
      data: {'token': fcmToken, 'platform': platform, 'device_id': deviceId},
    );
  }

  /// Deactivates this device's FCM token (called on logout). Best-effort.
  Future<void> unregisterDevice({
    required String token,
    required String fcmToken,
  }) async {
    try {
      await _authed(
        token,
      ).post('/auth/devices/unregister/', data: {'token': fcmToken});
    } on DioException {
      // Logging out should never fail because the network is down.
    }
  }

  Future<int> studentShareTripLocation({
    required String token,
    required int tripId,
  }) async {
    final response = await _authed(
      token,
    ).post('/student/trips/$tripId/share-location/');
    final data = response.data as Map<String, dynamic>;
    return int.tryParse(data['shared_count']?.toString() ?? '') ?? 0;
  }

  Future<List<LocationShareModel>> fetchParentTracking(String token) async {
    final response = await _authed(token).get('/parent/tracking/');
    return (response.data as List<dynamic>)
        .map(
          (item) => LocationShareModel.fromJson(
            (item as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<ParentSummaryModel> fetchParentSummary(String token) async {
    final response = await _authed(token).get('/parent/summary/');
    return ParentSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentSubscriptionModel> requestSubscription({
    required String token,
    String planName = 'اشتراك شهري',
    int durationDays = 30,
    int totalRides = 44,
  }) async {
    final response = await _authed(token).post(
      '/parent/subscriptions/request/',
      data: {
        'plan_name': planName,
        'duration_days': durationDays,
        'total_rides': totalRides,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final subscription = data['subscription'];
    return StudentSubscriptionModel.fromJson(
      subscription is Map ? subscription.cast<String, dynamic>() : const {},
    );
  }

  Dio _authed(String token) {
    return _dio..options.headers['Authorization'] = 'Bearer $token';
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) {
        return data['detail'].toString();
      }
      final firstValue = data.values.isEmpty ? null : data.values.first;
      if (firstValue != null) {
        return firstValue.toString().replaceAll('[', '').replaceAll(']', '');
      }
    }
    return 'حدث خطأ أثناء الاتصال بالخادم.';
  }

  Future<String> _deviceBindingId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('terhal_device_binding_id');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated =
        'terhal-${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}';
    await prefs.setString('terhal_device_binding_id', generated);
    return generated;
  }
}
