import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/api_service.dart';
import 'package:terhal_mobile/src/app.dart';
import 'package:terhal_mobile/src/models.dart';
import 'package:terhal_mobile/src/session_controller.dart';

class _PreviewSessionController extends SessionController {
  _PreviewSessionController() : super(ApiService()) {
    state = SessionState(studentHome: _homeData);
  }

  @override
  Future<void> bootstrap() async {}

  @override
  Future<void> refresh({bool retryAuthentication = true}) async {}
}

final _homeData = StudentHomeModel.fromJson({
  'student': {
    'name': 'أحمد علي عبدالرحمن',
    'code': 'STU-2026-0001',
    'faculty': 'علوم الحاسب',
    'academic_year': 'السنة الثانية',
  },
  'unread_notifications': 8,
  'due_payments': 1,
  'departure_booking': {
    'id': 1,
    'seat_number': '1',
    'status': 'confirmed',
    'qr_token': 'preview-token',
    'trip': {
      'id': 1,
      'trip_code': 'TR-2026-001',
      'direction': 'departure',
      'status': 'boarding',
      'departure_time': '07:15:00',
      'scheduled_arrival_time': '08:10:00',
      'available_seats': 12,
      'booking_count': 28,
      'attendance_count': 18,
      'absent_count': 0,
      'driver_name': 'السائق',
      'supervisor_name': 'المشرف',
      'notes': '',
      'route': {
        'id': 1,
        'code': 'NASR-BNU',
        'name': 'مدينة نصر - الجامعة الدولية',
        'origin_name': 'مدينة نصر',
        'destination_name': 'الحرم الجامعي',
        'distance_km': 31,
        'estimated_duration_minutes': 55,
        'path_points': [],
        'stops': [],
      },
      'bus': {
        'id': 1,
        'code': 'B-102',
        'plate_number': 'أ ب ج 1234',
        'capacity': 40,
        'status': 'active',
        'color': '#A71920',
      },
    },
  },
});

void main() {
  testWidgets('student home stays responsive while scrolling a compact phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => _PreviewSessionController()),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: ThemeData(fontFamily: 'Tajawal'),
          home: StudentHomePage(
            onOpenTracking: (_) {},
            onSwitchTab: (_) {},
            onShowSupport: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final scrollable = find.byType(CustomScrollView);
    await tester.drag(scrollable, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(scrollable, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
