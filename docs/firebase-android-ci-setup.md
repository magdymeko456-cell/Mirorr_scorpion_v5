# ربط Firebase Android عبر CI

## الحالة المعتمدة

يستخدم Mirror Scorpion v4 تطبيق Android المسجل في مشروع Firebase `mirorr-d11b2` بالمعرف غير القابل للتغيير `com.mirror.scorpion.v4`. يُحفظ ملف `google-services.json` خارج Git في GitHub Actions Secret باسم `ANDROID_GOOGLE_SERVICES_JSON`، ثم يُنشأ في `android/app/` داخل عامل البناء فقط ويحذف بعد محاولة البناء.

| العنصر | القرار |
|---|---|
| Android application ID | `com.mirror.scorpion.v4` |
| مشروع Firebase | `mirorr-d11b2` |
| موضع ملف Android أثناء البناء | `android/app/google-services.json` |
| حفظ الملف | GitHub Actions Secret فقط، ولا يُتتبع في Git |
| تهيئة Flutter الحالية | Android فقط عبر `Firebase.initializeApp()` |

تتطلب وثائق Firebase وضع ملف `google-services.json` في جذر وحدة Android وإضافة Google services Gradle plugin؛ ينفذ CI هاتين الخطوتين بعد إنشاء شجرة Android النظيفة [1]. وحزمة `firebase_core` هي نقطة الدخول الرسمية لربط Flutter بخدمات Firebase [2].

## التحقق

يفشل CI عمداً إن كان السر مفقوداً أو إن كان ملف الإعداد لا يحتوي على Android package name المعتمد. لا يُستخدم ملف حساب خدمة، ولا يُخزن أي مفتاح مزود أو مفتاح RSA خاص في التطبيق أو المستودع.

> هذه المرحلة لا تضيف ترجمة أو OCR أو صوتاً وهمياً؛ هي تهيئة اتصال Firebase الأساسية فقط قبل إضافة الخدمات واحدة واحدة.

## المراجع

[1]: https://firebase.google.com/docs/android/setup "Add Firebase to your Android project"
[2]: https://firebase.google.com/docs/flutter/setup "Get started with Firebase in your Flutter project"
