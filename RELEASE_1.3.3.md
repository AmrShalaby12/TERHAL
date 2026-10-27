# ترحال 1.3.3+9 — إصلاح إعدادات بدء التشغيل

## الخلل المؤكد في السورس

في iOS Release، كان `ApiService` يرمي `StateError: API_BASE_URL is required for production builds.` عند غياب `--dart-define=API_BASE_URL=...`. يتم إنشاء الخدمة من provider الذي تقرؤه أول شاشة، ولذلك يفشل بناء الواجهة قبل الوصول إلى تسجيل الدخول. هذه حالة قابلة للحدوث عند Archive من Xcode دون إعدادات Flutter السابقة.

لم يتم استلام سجل الجهاز أو ملف IPA المنشور، لذلك لم يتأكد أن هذه الحالة هي سبب الشاشة البيضاء في النسخة المقبولة على App Store.

## التغيير

- Release يستخدم `https://ter7al.noxusai.online/api` افتراضيًا عند غياب override.
- يمكن استمرار استخدام HTTPS API override، مع إبقاء رفض الإعدادات الصريحة غير الصحيحة أو غير الآمنة.
- عناوين التطوير المحلية لم تتغير.
- لا تغيير في Bundle ID أو توقيع Apple أو AppDelegate/SceneDelegate.

## إعادة إصدار iOS

1. اسحب آخر commit وافتح المشروع على Mac باستخدام Flutter 3.44.0 وXcode.
2. أكمل إعدادات Firebase وApple Team والتوقيع الموضحة في `STORE_RELEASE.md` مع الحفاظ على هوية تطبيق App Store الفعلية.
3. اتبع أمر البناء الحالي في `STORE_RELEASE.md`؛ تم رفع الأرقام بعد هذا الإصلاح إلى Version 1.3.4 وBuild 10، ثم إلى Build 19 لإتاحة الترقية على Google Play. لا تستخدم Archive الإصدار السابق.
4. اختبر النسخة على iPhone عبر TestFlight، بما يشمل أول فتح وتحديث تثبيت سابق، قبل النشر العام.
5. إذا استمرت الشاشة البيضاء، احفظ سجل الإقلاع من Xcode > Devices and Simulators أو Console، وحدد أول exception. يلزم هذا السجل لتحديد سبب فشل النسخة المنشورة بدقة.

نجح 24 اختبار Flutter، منها 5 اختبارات لإعدادات Release بدون build defines وoverrides وعناوين التطوير، ونجح تحليل الملفات المعدلة دون ملاحظات. هذه مراجعة واختبارات Flutter على Linux، وليست اختبار تشغيل iOS أو إصدار IPA موقّع.
