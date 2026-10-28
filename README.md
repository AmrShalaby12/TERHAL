# ترحال (TERHAL)

سورس Flutter وملفات Android وiOS اللازمة لتحديث تطبيق ترحال. الباك إند يعمل على خادم الإنتاج ولا يدخل ضمن حزمة تسليم المتاجر.

- تعليمات إصدار المتاجر: [STORE_RELEASE.md](STORE_RELEASE.md)
- تطبيق Flutter: `mobile/`
- بناء iOS للإنتاج من آخر سورس: [IOS_PRODUCTION_BUILD.md](IOS_PRODUCTION_BUILD.md)
- Android App Bundle الحالي: [Terhal-1.3.4+19.aab](dist/Terhal-1.3.4+19.aab)
- تصحيح هوية تطبيق Google Play وإعدادات Firebase: [RELEASE_1.3.2.md](RELEASE_1.3.2.md)
- إصلاح بدء التشغيل عند إنشاء Archive بدون إعدادات API: [RELEASE_1.3.3.md](RELEASE_1.3.3.md)
- تفاصيل التحديث والمراجعة البصرية: [RELEASE_1.3.1.md](RELEASE_1.3.1.md)

إصدار السورس الحالي: `1.3.5+20`. عنوان API الافتراضي في كل أوضاع التشغيل هو `https://ter7al.noxusai.online/api`، ولا يوجد رجوع تلقائي إلى localhost. ملف Android AAB الجاهز أعلاه ما زال `1.3.4+19`؛ إعدادات الإصدار الجديد تتطلب بناء جديد من السورس. اسم حزمة Android هو `com.noxusAI.mobile`.

ملفات APK وAAB القديمة بالإصدارات 1.3.0 و1.3.1 تحمل اسم حزمة مختلفًا؛ لا تستخدمها لتحديث التطبيق المنشور على Google Play.
