# ترحال iOS — إعداد إنتاج 1.3.5+20

العنوان الافتراضي في `mobile/lib/src/api_service.dart` هو:

```dart
static const productionApiBaseUrl = 'https://ter7al.noxusai.online/api';
```

يستخدم التطبيق هذا العنوان دون الحاجة إلى `API_BASE_URL` في Debug وProfile وRelease. شرط `API_BASE_URL is required for production builds` والرجوع التلقائي إلى `127.0.0.1` غير موجودين في هذا الإصدار. إذا كان الملف المحلي يحتويهما، فهو نسخة قديمة؛ لا تبنِ منها Archive.

## البناء على Mac

احتفظ بإعدادات Apple Team والتوقيع وBundle ID الخاصة بالتطبيق المنشور. أكمل متطلبات Firebase والتوقيع الموضحة في `STORE_RELEASE.md`. لا تغيّر هوية التطبيق المنشور لتطابق أي قيمة افتراضية في المشروع.

بعد سحب آخر `main`، نفّذ من مجلد المستودع:

```bash
cd mobile
flutter --version
flutter clean
flutter pub get
flutter build ipa --release \
  --build-name=1.3.5 \
  --build-number=20 \
  --dart-define=APP_MODE=terhal \
  --dart-define=API_BASE_URL=https://ter7al.noxusai.online/api \
  --dart-define=DASHBOARD_URL=https://ter7al.noxusai.online/dashboard/overview/
```

نسخة Flutter المستخدمة لمراجعة السورس: 3.44.0. تمرير عنوان الإنتاج في الأمر أعلاه صريح للتوثيق؛ عدم تمريره لا يمنع تشغيل التطبيق.

ارفع الـArchive الناتج حديثًا، وتأكد من ظهور Version 1.3.5 وBuild 20. استخدم build أعلى إذا كان 20 مستخدمًا بالفعل. لا تُعد رفع Archive قديم محفوظ في Organizer.

اختبر نفس build عبر TestFlight على آيفون قبل النشر. نجاح Debug من Xcode لا يثبت أن النسخة الموزّعة تعمل. لم يُبنَ IPA أو يُختبر iOS على هذه البيئة التي تعمل بنظام Linux؛ إذا استمر البياض بعد هذا البناء، يلزم سجل الجهاز لتحديد السبب المتبقي.

التحقق من السورس: نجحت اختبارات Flutter الـ26، منها 7 اختبارات لإعدادات عنوان API، ونجح التحليل للملفات المعدلة. فُحص بدء إنشاء ApiService دون أي build defines، والعنوان الافتراضي في Release والتطوير، ورفض عناوين localhost في Release.
