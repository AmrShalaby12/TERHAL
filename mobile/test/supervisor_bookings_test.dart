import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/api_service.dart';
import 'package:terhal_mobile/src/app.dart';
import 'package:terhal_mobile/src/models.dart';
import 'package:terhal_mobile/src/session_controller.dart';

BookingModel sampleBooking(int id, {String status = 'booked'}) =>
    BookingModel.fromJson({
      'id': id,
      'student_name': 'طالب رقم $id',
      'student_phone': '01012345678',
      'status': status,
      'payment_method': 'cash',
      'payment_status': status == 'pending_payment' ? 'pending' : 'paid',
      'pickup_stop': {'id': 1, 'name': 'نقطة بنها'},
      'trip': {
        'id': 1,
        'trip_code': 'TEST-TRIP',
        'date': '2026-10-10',
        'direction': 'departure',
        'status': 'scheduled',
        'departure_time': '07:00:00',
        'route': {'id': 26, 'name': 'خط بنها الإقليمي', 'campus_code': 'BNU'},
        'bus': <String, dynamic>{},
      },
    });

class ManifestController extends SessionController {
  ManifestController() : super(ApiService(), restoreSession: false) {
    state = SessionState(
      bookings: [
        for (var i = 1; i <= 105; i++) sampleBooking(i),
        sampleBooking(106, status: 'pending_payment'),
      ],
    );
  }
  @override
  Future<void> refresh({bool retryAuthentication = true}) async {}
}

class PartialFailureApi extends ApiService {
  bool failBookings = false;
  @override
  Future<AuthPayload> login({
    required String phoneNumber,
    required String password,
  }) async => AuthPayload(
    user: UserProfile.fromJson({
      'id': 143,
      'role': 'supervisor',
      'full_name': 'أحمد الجزار',
    }),
    accessToken: 'token',
    refreshToken: 'refresh',
  );
  @override
  Future<SupervisorOverviewModel> fetchSupervisorOverview(String token) async =>
      throw Exception('overview unavailable');
  @override
  Future<List<TripModel>> fetchTrips(String token) async => [
    sampleBooking(1).trip,
  ];
  @override
  Future<List<BookingModel>> fetchBookings(String token) async {
    if (failBookings) throw Exception('offline');
    return [sampleBooking(1)];
  }

  @override
  Future<List<NotificationModel>> fetchNotifications(String token) async =>
      throw Exception('notifications unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Tajawal')..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    await font.load();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('manifest parses names, phones and payment states safely', () {
    final booking = sampleBooking(1);
    expect(booking.studentName, 'طالب رقم 1');
    expect(booking.studentPhone, '01012345678');
    expect(booking.pickupStop!.name, 'نقطة بنها');
    expect(booking.isConfirmed, isTrue);
    expect(sampleBooking(2, status: 'pending_payment').isConfirmed, isFalse);
    expect(BookingModel.fromJson({}).studentPhone, isEmpty);
  });

  test(
    'failed overview or notifications cannot hide fetched bookings',
    () async {
      final api = PartialFailureApi();
      final controller = SessionController(api, restoreSession: false);
      await controller.login(phoneNumber: '01112209517', password: 'test');
      expect(controller.state.bookings.single.studentName, 'طالب رقم 1');
      expect(controller.state.trips.length, 1);
      expect(controller.state.errorMessage, contains('الإحصائيات'));
      api.failBookings = true;
      await controller.refresh();
      expect(controller.state.bookings.length, 1);
      expect(controller.state.errorMessage, contains('الحجوزات'));
      controller.dispose();
    },
  );

  for (final width in [360.0, 800.0]) {
    testWidgets('complete searchable manifest fits width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => ManifestController()),
          ],
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Tajawal'),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: SupervisorBookingsPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('عدد الحجوزات المعروضة: 105'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'طالب رقم 105');
      await tester.pumpAndSettle();
      expect(find.text('عدد الحجوزات المعروضة: 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('booking-105')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.descendant(of: find.byKey(const ValueKey('booking-105')), matching: find.text('طالب رقم 105')), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);
      expect(find.text('نقطة الركوب: نقطة بنها'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(SupervisorBookingsPage), matchesGoldenFile('goldens/supervisor-bookings-${width.toInt()}.png'));
    });
  }
}
