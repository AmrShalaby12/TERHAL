import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/api_service.dart';
import 'package:terhal_mobile/src/app.dart';
import 'package:terhal_mobile/src/models.dart';
import 'package:terhal_mobile/src/session_controller.dart';

final longBody =
    '${List.filled(14, 'تم تحديث بيانات الاشتراك ومواعيد الرحلات. يمكنك مراجعة حسابك لمعرفة التفاصيل.').join('\n')}\nنهاية الرسالة بالكامل';

class PreviewController extends SessionController {
  void publish(String title) {
    state = state.copyWith(
      appExperience: AppExperienceModel(
        announcementIsActive: true,
        announcementPopupEnabled: true,
        announcementTitle: title,
        announcementBody: 'كل التفاصيل ومواعيد الرحلات متاحة الآن.',
      ),
    );
  }

  PreviewController({bool signedIn = true, bool popup = false})
    : super(ApiService(), restoreSession: false) {
    final trip = {
      'id': 1,
      'trip_code': 'TR-2026-01',
      'date': DateTime.now().toIso8601String(),
      'direction': 'departure',
      'status': 'scheduled',
      'departure_time': '14:00',
      'available_seats': 20,
      'route': {
        'name': 'جامعة بنها الأهلية · الخط الزراعي',
        'origin_name': 'بنها',
        'destination_name': 'العبور',
      },
      'bus': {'code': 'BUS-12'},
      'driver_name': 'محمد أحمد',
    };
    state = SessionState(
      auth: signedIn
          ? AuthPayload(
              user: UserProfile.fromJson({
                'id': 1,
                'username': 'student',
                'role': 'student',
                'full_name': 'أحمد علي عبدالرحمن',
                'university_name': 'جامعة بنها الأهلية',
                'student_profile': {
                  'faculty': 'كلية الهندسة',
                  'academic_year': 'السنة الثالثة',
                },
              }),
              accessToken: 'preview',
              refreshToken: '',
            )
          : null,
      studentHome: StudentHomeModel.fromJson({
        'student': {'name': 'أحمد علي عبدالرحمن'},
        'support_contacts': [
          {
            'key': 'direct',
            'title': 'مشرف الخط',
            'subtitle': 'استفسارات الرحلات',
            'phone': '01012345678',
          },
        ],
      }),
      trips: [TripModel.fromJson(trip)],
      bookings: [
        BookingModel.fromJson({
          'id': 1,
          'status': 'booked',
          'qr_token': 'TEST-BOOKING-1',
          'trip': trip,
        }),
      ],
      notifications: [
        NotificationModel(
          id: 1,
          title: 'تحديث رصيد الاشتراك ومواعيد الرحلات الخاصة بك',
          body: longBody,
          type: 'payment',
          isRead: false,
          createdAt: DateTime(2026, 1, 1, 12),
        ),
      ],
      paymentsLoaded: true,
      payments: [
        for (final entry in {1: 'paid', 2: 'pending', 3: 'failed'}.entries)
          PaymentModel(
            id: entry.key,
            invoiceNumber: 'INV-20261024-00${entry.key}',
            amount: 7231,
            status: entry.value,
            paymentMethod: 'cash',
            createdAt: DateTime(2026, 10, 24, 12),
            paidAt: entry.key == 1 ? DateTime(2026, 10, 24, 13) : null,
            subscriptionId: 12,
          ),
      ],
      appExperience: AppExperienceModel(
        announcementIsActive: popup,
        announcementPopupEnabled: popup,
        announcementTitle: 'مواعيد ترحال الجديدة',
        announcementBody: 'تابع جدول الرحلات واحجز رحلتك من الاشتراك.',
      ),
    );
  }
  @override
  Future<void> refresh({bool retryAuthentication = true}) async {}
  @override
  Future<void> refreshAppExperience() async {}
  @override
  Future<void> markNotificationRead(int id) async {}
}

void main() {
  testWidgets('external link platform failures stay quiet', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    expect(await openExternalLink('https://wa.me/201012345678'), isFalse);
    expect(await openExternalLink('javascript:alert(1)'), isFalse);
  });
  setUpAll(() async {
    final fonts = FontLoader('Tajawal');
    for (final weight in ['Regular', 'Medium', 'Bold', 'ExtraBold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Tajawal-$weight.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test('dashboard phones become international WhatsApp links', () {
    for (final phone in [
      '01012345678',
      '+20 101 234 5678',
      '٠١٠١٢٣٤٥٦٧٨',
      '00201012345678',
    ]) {
      expect(
        SupportContactModel(
          key: '',
          title: '',
          subtitle: '',
          phone: phone,
        ).whatsappUrl,
        'https://wa.me/201012345678',
      );
    }
  });

  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('all student tabs fit width $width with large system text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith((_) => PreviewController())],
          child: const TerhalApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(StudentShell));
        for (final asset in ['assets/images/LOGO.png', 'assets/images/terhallanengpackgond.png', 'assets/images/terhal_identity_bus_bnu_v3.png']) {
          await precacheImage(AssetImage(asset), context);
        }
        for (final width in [520, 820, 1080]) {
          await precacheImage(ResizeImage(const AssetImage('assets/images/terhal_identity_bus_bnu_v3.png'), width: width), context);
        }
      });
      await tester.pumpAndSettle();
      for (final label in [
        'الرئيسية',
        'الرحلات',
        'حجوزاتي',
        'الحضور',
        'الإشعارات',
        'حسابي',
      ]) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull, reason: '$label at $width');
        if (width == 390 && (label != 'الرئيسية' || autoUpdateGoldenFiles)) {
          await expectLater(
            find.byType(StudentShell),
            matchesGoldenFile('goldens/polish-$label.png'),
          );
        }
      }
      final carousel = find.text('صافي ما تم دفعه فعليًا');
      await tester.ensureVisible(carousel);
      await tester.tap(carousel);
      await tester.pumpAndSettle();
      expect(find.byType(InvoicesPage), findsOneWidget);
      expect(find.text('تاريخ الإنشاء'), findsWidgets);
      expect(tester.takeException(), isNull);
      if (width == 390)
        await expectLater(
          find.byType(InvoicesPage),
          matchesGoldenFile('goldens/polish-invoices.png'),
        );
    });
  }
  testWidgets('notification opens all text in a scrollable page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith((_) => PreviewController())],
        child: const TerhalApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإشعارات').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض الرسالة كاملة'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationDetailsPage), findsOneWidget);
    expect(find.text(longBody), findsOneWidget);
    await expectLater(
      find.byType(NotificationDetailsPage),
      matchesGoldenFile('goldens/polish-message.png'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'popup is dismissible and updates do not repeatedly interrupt students',
    (tester) async {
      final controller = PreviewController(popup: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith((_) => controller)],
          child: const TerhalApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await expectLater(
        find.byType(Dialog),
        matchesGoldenFile('goldens/polish-popup.png'),
      );
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();
      controller.publish('إعلان جديد');
      await tester.pumpAndSettle();
      expect(find.text('إعلان جديد'), findsOneWidget);
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();
      controller.publish('إعلان جديد');
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('support displays configured contacts', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith((_) => PreviewController())],
        child: const TerhalApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدعم'));
    await tester.pumpAndSettle();
    expect(find.text('مشرف الخط'), findsOneWidget);
    expect(find.textContaining('تواصل عبر واتساب'), findsOneWidget);
    await expectLater(
      find.byType(SupportSheet),
      matchesGoldenFile('goldens/polish-support.png'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('landing button reachable on short screen with large fonts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            (_) => PreviewController(signedIn: false),
          ),
        ],
        child: const TerhalApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ابدأ رحلتك'));
    await tester.tap(find.text('ابدأ رحلتك'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
