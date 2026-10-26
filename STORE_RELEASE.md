# تسليم تحديث ترحال للمتاجر

هذا المستودع يحتوي على سورس التطبيق وملفات البناء. نشر تحديث للمتاجر يتطلب أيضًا صلاحيات الحسابات ومطابقة التوقيع وهوية التطبيق المنشور؛ متطلبات iOS غير المكتملة موضحة أدناه.

## الإصدار الحالي

- Flutter: `3.44.0`
- Dart: `3.12.x`
- إصدار السورس: `1.3.4+10` (Version 1.3.4، Build 10)
- ملف Android AAB الجاهز: `1.3.4+10` (يشمل إصلاح بدء التشغيل)
- Android application ID: `com.noxusAI.mobile` (بنفس حالة الأحرف)
- iOS bundle ID: `online.noxusai.terhal`
- Production API: `https://ter7al.noxusai.online/api`

## Android

تم تنزيل إعدادات Firebase الأصلية للحزمة `com.noxusAI.mobile` من مشروع `ter7al-e4c20`، وهو نفس مشروع خادم الإشعارات. مفتاح Android الموجود وملف `key.properties` لم يتغيرا. لم تتم مقارنة المفتاح بمفتاح الرفع المسجل في Google Play؛ يجب التحقق من التطابق قبل النشر.

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release \
  --build-name=1.3.4 \
  --build-number=10 \
  --dart-define=APP_MODE=terhal \
  --dart-define=API_BASE_URL=https://ter7al.noxusai.online/api \
  --dart-define=DASHBOARD_URL=https://ter7al.noxusai.online/dashboard/overview/
```

الناتج المطلوب لـGoogle Play هو:

`mobile/build/app/outputs/bundle/release/app-release.aab`

آخر نسخة AAB موقّعة تم بناؤها (1.3.4+10) موجودة في:

`dist/Terhal-1.3.4+10.aab`

قبل رفعها، تأكد من مطابقة شهادة مفتاح الرفع للمسجل في Play Console وأن آخر version code مرفوع أقل من 10. لم تتم مراجعة حساب Google Play من هذه البيئة.

بصمة SHA-256 لشهادة توقيع الملف الحالي:

`D0:ED:11:FA:1C:4B:19:8F:92:00:A7:B1:2E:53:D3:15:35:6D:9C:2C:22:DA:06:F5:59:72:6B:9F:10:B4:C7:DC`

ملفات APK وAAB بالإصدارات 1.3.0 و1.3.1 في `dist/` تحمل `com.allentravels.driver`؛ لا تستخدمها لتحديث تطبيق `com.noxusAI.mobile`.

## iOS

مشروع iOS مضبوط حاليًا على bundle ID `online.noxusai.terhal`؛ يجب مطابقته مع التطبيق الموجود في App Store Connect. قبل عمل Archive على جهاز macOS يجب على المبرمج:

1. إضافة `mobile/ios/Runner/GoogleService-Info.plist` الخاص بتطبيق iOS من Firebase؛ هذا الملف غير موجود في التسليم الحالي.
2. فتح `mobile/ios/Runner.xcworkspace` في Xcode، واختيار Apple Team الصحيح، وتفعيل Push Notifications وBackground Modes.
3. استخدام شهادة وتوقيع App Store Connect الخاصة بالحساب؛ شهادات Apple وملفات provisioning غير موجودة على خادم Linux الحالي.
4. التأكد أن رقم البناء أعلى من آخر build مرفوع على App Store Connect عند النشر.

```bash
cd mobile
flutter pub get
flutter build ipa --release \
  --build-name=1.3.4 \
  --build-number=10 \
  --dart-define=APP_MODE=terhal \
  --dart-define=API_BASE_URL=https://ter7al.noxusai.online/api \
  --dart-define=DASHBOARD_URL=https://ter7al.noxusai.online/dashboard/overview/
```

لا يمكن إنشاء أو توقيع ملف IPA على Linux؛ يجب تنفيذ خطوة iOS النهائية على macOS باستخدام Xcode وحساب Apple Developer المالك للتطبيق.

الإصدار 1.3.4 أعلى من الإصدار المنشور 1.2.4 الذي حدده المالك. رقم Build الحالي هو 10 بدل 9. بعد سحب التعديل، أنشئ Archive جديدًا بالأمر أعلاه وتأكد من ظهور Version 1.3.4 وBuild 10 في Organizer؛ إعادة رفع Archive قديم لا تُحدّث أرقامه. يجب أن تكون نسخة الإصدار المختارة في App Store Connect مطابقة، وألا يكون Build 10 مستخدمًا مسبقًا لذلك الإصدار.

من إصدار السورس 1.3.3، إعداد `API_BASE_URL` اختياري في Release: الافتراضي هو `https://ter7al.noxusai.online/api`. في الإصدارات السابقة، إغفاله في Archive كان يؤدي إلى StateError أثناء بناء أول شاشة. يجب إعادة بناء النسخة لإدخال الإصلاح.

## ملاحظات مهمة

- ارفع رقم `version` في `mobile/pubspec.yaml` في كل تحديث جديد.
- لا تغيّر Android application ID أو iOS bundle ID عند تحديث التطبيقات الحالية.
- اختبر الإشعارات والروابط الخارجية والموقع والكاميرا على أجهزة حقيقية قبل إرسال الإصدار للمراجعة.
