import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/app.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Tajawal')..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('premium landing fits a compact phone without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(fontFamily: 'Tajawal'),
        home: LandingScreen(onEnter: () {}),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(LandingScreen));
      await precacheImage(const AssetImage('assets/images/terhal_identity_bus_bnu_v3.png'), context);
      await precacheImage(const AssetImage('assets/images/LOGO.png'), context);
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LandingScreen),
      matchesGoldenFile('goldens/premium_landing_390x844.png'),
    );
  });
}
