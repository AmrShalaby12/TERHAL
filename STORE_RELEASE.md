# تسليم تحديث ترحال للمتاجر

هذه النسخة تحتوي على الملفات التي يحتاجها المبرمج لبناء ونشر التطبيق على Google Play وApp Store. ملفات البناء والكاش والنسخ الاحتياطية وبيانات التشغيل ليست جزءًا من المستودع.

## الإصدار الحالي

- Flutter: `3.44.0`
- Dart: `3.12.x`
- إصدار التطبيق: `1.3.1+7`
- Android application ID: `com.allentravels.driver`
- iOS bundle ID: `online.noxusai.terhal`
- Production API: `https://ter7al.noxusai.online/api`

## Android

ملفات Firebase ومفتاح Android الحالي وملف `key.properties` موجودة في المشروع حتى يمكن إصدار تحديث بنفس هوية التطبيق. تعامل معها كأسرار ولا تغيّر المفتاح عند تحديث التطبيق الموجود على المتجر.

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release \
  --build-name=1.3.1 \
  --build-number=7 \
  --dart-define=APP_MODE=terhal \
  --dart-define=API_BASE_URL=https://ter7al.noxusai.online/api \
  --dart-define=DASHBOARD_URL=https://ter7al.noxusai.online/dashboard/overview/
```

الناتج المطلوب لـGoogle Play هو:

`mobile/build/app/outputs/bundle/release/app-release.aab`

نسخة APK الجاهزة للاختبار موجودة في:

`dist/Terhal-1.3.1+7.apk`

## iOS

تم تجهيز مشروع iOS بالـbundle ID الرسمي `online.noxusai.terhal`، وتصاريح الكاميرا والموقع والإشعارات. قبل عمل Archive على جهاز macOS يجب على المبرمج:

1. إضافة `mobile/ios/Runner/GoogleService-Info.plist` الخاص بتطبيق iOS من Firebase؛ هذا الملف غير موجود في التسليم الحالي.
2. فتح `mobile/ios/Runner.xcworkspace` في Xcode، واختيار Apple Team الصحيح، وتفعيل Push Notifications وBackground Modes.
3. استخدام شهادة وتوقيع App Store Connect الخاصة بالحساب؛ شهادات Apple وملفات provisioning غير موجودة على خادم Linux الحالي.
4. التأكد أن رقم البناء أعلى من آخر build مرفوع على App Store Connect عند النشر.

```bash
cd mobile
flutter pub get
flutter build ipa --release \
  --build-name=1.3.1 \
  --build-number=7 \
  --dart-define=APP_MODE=terhal \
  --dart-define=API_BASE_URL=https://ter7al.noxusai.online/api \
  --dart-define=DASHBOARD_URL=https://ter7al.noxusai.online/dashboard/overview/
```

لا يمكن إنشاء أو توقيع ملف IPA على Linux؛ يجب تنفيذ خطوة iOS النهائية على macOS باستخدام Xcode وحساب Apple Developer المالك للتطبيق.

## ملاحظات مهمة

- ارفع رقم `version` في `mobile/pubspec.yaml` في كل تحديث جديد.
- لا تغيّر Android application ID أو iOS bundle ID عند تحديث التطبيقات الحالية.
- اختبر الإشعارات والروابط الخارجية والموقع والكاميرا على أجهزة حقيقية قبل إرسال الإصدار للمراجعة.
