# تهيئة بيئة اختبار Google/Firebase لـMirror Scorpion v4

## القرار المعتمد

تم اعتماد Google/Firebase لطبقة الاختبار والإنتاج. يحتفظ Flutter بالواجهة، وML Kit بالمهام المحلية، بينما تحتفظ Cloud Functions بالمفاتيح وعمليات الترجمة والتفريغ والذكاء والفيديو والتحقق من PRO. لا يضع التطبيق مفتاح ترجمة أو LLM أو RSA خاصاً داخل APK.

مشروع Firebase المعتمد للاختبار هو `mirorr-d11b2`. Project ID غير سري ويكفي لربط إعداد الدوال، أما Project Number وملفات حساب الخدمة فلا توضع في Flutter أو GitHub.

## تهيئة مشروع Firebase

ينشئ مالك المشروع مشروع Firebase ثم يشغّل من جذر مشروع Flutter، بعد تثبيت Flutter وFirebase CLI وFlutterFire CLI:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

ينشئ `flutterfire configure` تطبيق Android داخل مشروع Firebase وملف `lib/firebase_options.dart`. يعرّف هذا الملف التطبيق والمنصة بمعرّفات غير سرية، ثم يُستدعى `Firebase.initializeApp` عند بدء التطبيق [1]. لا يُنشأ `firebase_options.dart` يدوياً ولا يُخزن حساب خدمة Google أو أي مفتاح مزود داخل المستودع.

## حزم Flutter المعتمدة للاختبار

| الغرض | الحزمة | الإصدار المتحقق وقت التخطيط |
|---|---|---|
| التهيئة | `firebase_core` | `^4.13.0` [2] |
| الدوال الخلفية | `cloud_functions` | `^6.3.6` [3] |
| ملفات الصوت والمستندات والفيديو | `firebase_storage` | `^13.4.6` [4] |
| رسائل الإلهام وإشعارات الحالة | `firebase_messaging` | `^16.5.0` [5] |
| OCR محلي | `google_mlkit_text_recognition` | `^0.17.1` [6] |
| ترجمة أوفلاين | `google_mlkit_translation` | `^0.15.1` [7] |

تُضاف هذه الحزم بعد إنشاء إعداد Firebase، ثم يعاد تشغيل `flutterfire configure` عند إضافة منتج Firebase جديد كما توصي وثائق FlutterFire [1]. يفرض OCR/ML Kit على Android إعدادات SDK الحديثة التي تولدها شجرة Android النظيفة في CI، ويعمل فقط على Android/iOS لا على واجهة الويب [6] [7].

## عقود Cloud Functions

| الدالة القابلة للاستدعاء | المدخلات | المخرجات | قاعدة الاختبار |
|---|---|---|---|
| `translateText` | نص، لغة مصدر، لغة هدف | نص مترجم، مزود/لغة مكتشفة | لا يرد بنص افتراضي عند فشل المزود. |
| `transcribeAudio` | مرجع Storage، لغات | تفريغ، ترجمة، طول معالجة | يرفض صيغة أو حجماً غير مدعومين قبل الاستدعاء الخارجي. |
| `processDocument` | مرجع Storage، لغة، صفحات | نص أصلي، ترجمة، صفحات معالجة | يعيد تقدماً وحالة، ويطبق خمس صفحات فقط كسياسة اختبار. |
| `generateInspiration` | سياق اختياري، لغة الجهاز | رسالة ومصدر/وقت | يمر بفلتر سلامة ولا يقدم تشخيصاً طبياً أو نفسياً. |
| `createStoryVideo` | معرّف القصة، لغة، أسلوب | معرف مهمة وحالة لاحقة | لا يعلن نجاحاً قبل رابط ملف فيديو حقيقي. |
| `verifyProPatch` | معرّف تثبيت، باتش MS4 | صلاحية، انتهاء، مزايا | يقرأ المفتاح العام من إعدادات الخادم ويتحقق من الوقت الخادمي. |
| `registerDevice` | رمز FCM، لغة، إعداد الإلهام | تأكيد غير حساس | يستخدم فقط لإشعارات اختارها المستخدم. |

## مخازن Firebase

يستخدم Cloud Storage مسارات منفصلة ومحددة العمر: `uploads/audio/` و`uploads/documents/` و`results/video/`. تضبط قواعد Storage لاحقاً لتمنع القراءة العامة، وتقيّد حجم الملف ونوعه ومالك الرفع. تحفظ Firestore بيانات اختيارية فقط: حالة المهمة، تفضيل لغة، سجل تحقق PRO غير حساس، ومؤشر محتوى قصصي؛ لا يخزن النص الخاص أو عينة صوت المستخدم بلا موافقة صريحة.

## ترتيب التفعيل

1. ينشأ مشروع Firebase باسم منفصل للاختبار مع ضبط تنبيه للميزانية.
2. يُشغّل `flutterfire configure` ويُضاف `firebase_options.dart`.
3. تضاف حزم Firebase وML Kit، ثم ينجح `flutter analyze` و`flutter test` وAPK في GitHub Actions.
4. تُنشأ الدوال بأجوبة فشل صادقة واختبارات Emulator أولاً، ثم تربط المزودات الخارجية واحداً واحداً.
5. لا تُفعل أي بوابة PRO قبل اختبار كل دالة على APK حقيقي.

## المراجع

[1]: https://firebase.google.com/docs/flutter/setup "Get started with Firebase in your Flutter project"
[2]: https://pub.dev/packages/firebase_core "firebase_core"
[3]: https://pub.dev/packages/cloud_functions "cloud_functions"
[4]: https://pub.dev/packages/firebase_storage "firebase_storage"
[5]: https://pub.dev/packages/firebase_messaging "firebase_messaging"
[6]: https://pub.dev/packages/google_mlkit_text_recognition "google_mlkit_text_recognition"
[7]: https://pub.dev/packages/google_mlkit_translation "google_mlkit_translation"
