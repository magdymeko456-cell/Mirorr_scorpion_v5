# معمارية Mirror Scorpion v4 على Flutter

## قرار الهجرة

تُبنى v4 في المسار الجديد على **Flutter/Dart** بدلاً من Expo. لا تُنقل ملفات Expo أو Android الناتجة منه إلى شجرة Flutter؛ بل يُنشأ مشروع Flutter نظيف ثم تُنقل الوظائف وفق عقود واضحة. يزيل ذلك تضارب Gradle ومكتبات Flutter الذي ظهر في المحاولات السابقة، ويحافظ على قابلية تنفيذ عناصر رسومية مخصصة للشطرنج وروبيك ضمن إطار Flutter.

> فشل GitHub الأخير ليس دليلاً على فشل Flutter، بل على أن المستودع البعيد كان يحتوي `pubspec.yaml` باسم `mirror_scorpion_v2` ومسار Flutter قديم مع اعتماد `path_provider: ^2.2.1` غير منشور. القاعدة الجديدة ستستخدم `path_provider: ^2.1.6`، وهو إصدار منشور في Pub.dev [1].

## أساس الإصدار والبناء

| المكوّن | قرار v4 على Flutter | سبب الاستقرار |
|---|---|---|
| Flutter | `3.44.7` مثبت في CI | لا يتم خلط إصدار Flutter عشوائي مع تبعيات قديمة؛ توصي وثائق المنصات بإصدارات Flutter المدعومة حسب تاريخ الإصدار [2]. |
| Dart SDK | يأخذه Flutter المثبت؛ يحدد `pubspec` نطاقاً متوافقاً فقط | يمنع تعارض `shared_preferences`/Dart الذي ظهر مع SDK قديم. |
| Android | مشروع نظيف مولّد بـ `flutter create`، Java 17 وAndroid SDK في CI | لا حقن متأخر لـ Gradle ولا نسخ ملفات Android من مشروع تالف. |
| إدارة الحزم | `flutter pub get` بعد مراجعة `pubspec.lock` | لا تثبيت قسري لاعتماد غير موجود. |
| CI | Flutter فقط؛ لا Node/Expo ولا `expo prebuild` | يعكس بنية التطبيق الفعلية. |

## بنية الملفات المقترحة

```text
lib/
  app/
    app.dart                    # MaterialApp والـ theme والمسارات
    router.dart                 # GoRouter أو جدول routes ثابت
    theme/royal_dark_theme.dart # ألوان Royal Dark والخطوط
  core/
    network/api_client.dart     # REST إلى خدمات AI/OCR/PRO
    storage/local_store.dart    # SharedPreferences وملفات التطبيق
    security/pro_activation.dart
    platform/floating_overlay.dart
  features/
    home/                       # لوحة الكروت الستة
    translation/                # نص، صوت، حزم لغات
    dialogue/                   # حوار ثنائي اللغة
    documents/                  # اختيار ملف، كاميرا، OCR، عرض مزدوج
    stories/                    # مصادر، تنزيل، TTS، سيناريو فيديو
    games/                      # شطرنج، روبيك، مؤقت
    settings/                   # لغة، تنزيلات، PRO، عن التطبيق
android/
  app/src/main/kotlin/.../overlay/ # MethodChannel + Foreground Service
test/
  unit/                         # تحويل الباتش، اللغة، المصادر، الساعة
  widget/                       # الكروت الستة وحالات الخطأ
```

## الكروت الستة: ما يُنقل وكيف

| الكرت | واجهة Flutter | تنفيذ حقيقي في المرحلة الأولى | مرحلة لاحقة مشروطة |
|---|---|---|---|
| الترجمة النصية | `TextField` ثنائي، اختيار لغة، مايك ودبوس | نص، نسخ، مشاركة، تسجيل، رفع ملف، حفظ آخر لغة | توسيع قائمة 100+ لغة بعد تثبيت محرك/خدمة الترجمة. |
| الحوار | فقاعات حوار واتجاه RTL/LTR وزر تبديل | إرسال/استقبال وترجمة جمل واقعية عبر API | وضع محادثة مستمر ومشاركة صوت فوري. |
| المستندات والعدسة | كاميرا/اختيار ملف، progress، شاشة أصل/ترجمة | OCR حقيقي عبر ML Kit للصور أو خدمة خادم للـPDF؛ انتظار UI ثلاث ثوانٍ لا يخفي فشل OCR | PDF متعدد الصفحات وتحرير مرئي كامل. |
| القصص والإلهام | فهرس، قراءة، المزيد، زر TTS | محتوى JSON محلي ومصادر قابلة للتنزيل، فلتر قصة المستخدم، سيناريو فيديو نصي | إخراج MP4 يتطلب مزود فيديو مستقل. |
| الألعاب | لوحة شطرنج مخصصة ومكعب قابل للتفاعل | قواعد شطرنج وChess Clock وروبيك تعليمي مع حل | مشاهد ثلاثية الأبعاد كاملة تحتاج تجربة جهاز؛ `flame_3d` ما زال يقدم دعم 3D تجريبياً [3]. |
| الإعدادات وPRO | لغات أوف لاين، حالة الفقاعة، معرّف تثبيت، باتش | تحميل حالة محلية، نسخ المعرف، إرسال الباتش لخادم التحقق | متجر دفع/إلغاء ترخيص وحد محاولات. |

## حزم البداية المراجعة

الحزم الآتية هي نقطة انطلاق وليست قائمة نهائية؛ تُثبت في مشروع Flutter الجديد مرة واحدة، ثم يُحفظ `pubspec.lock` الناتج. لا تستعاد قيمة `path_provider: ^2.2.1` غير الموجودة.

```yaml
environment:
  sdk: ">=3.9.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  http: ^1.3.0
  shared_preferences: ^2.5.5
  path_provider: ^2.1.6
  permission_handler: ^11.4.0
  speech_to_text: ^6.6.2
  flutter_tts: ^4.1.0
  record: ^6.2.0
  file_picker: ^8.3.7
  image_picker: ^1.1.2
  camera: ^0.11.1+1
  google_mlkit_text_recognition: ^0.15.1
  google_mlkit_translation: ^0.17.0
  flutter_local_notifications: ^19.0.0
  share_plus: ^10.1.4
  url_launcher: ^6.3.1
```

## الخدمات الخارجية وعقود API

تستمر خدمات الذكاء الاصطناعي وOCR وPRO على الخادم؛ Flutter لا يحمل أسرار LLM أو مفتاح RSA الخاص. يعتمد العميل واجهات REST مختصرة، ويظهر فشل الشبكة بدلاً من ملء الشاشة بنتيجة وهمية.

| المسار | طلب العميل | استجابة الخادم المطلوبة |
|---|---|---|
| `POST /api/translate` | `text`, `sourceLanguage`, `targetLanguage` | نص مترجم ولغة مكتشفة |
| `POST /api/audio/transcribe-translate` | ملف صوتي، لغات | تفريغ وترجمة حقيقيان |
| `POST /api/documents/ocr` | صورة/PDF ولغة مستهدفة | نص أصلي ومترجم وحالة واضحة |
| `POST /api/pro/activate` | `deviceId`, `MS4.payload.signature` | `valid`, سبب الرفض، الخطة والانتهاء |
| `GET /api/pro/status` | لا شيء | توفر المفتاح العام فقط، دون كشفه |

## PRO وRSA-SHA256

يُنشئ Flutter معرّف تثبيت عشوائياً محلياً ويحفظه؛ لا يعتمد على Android ID أو رقم الهاتف. يعرضه للنسخ ثم يرسل الباتش الموقّع إلى الخادم. الخادم فقط يحتفظ بـ `MIRROR_PRO_ACTIVATION_PUBLIC_KEY` للتحقق؛ المفتاح الخاص يبقى خارج التطبيق والخادم. لا يكفي تخزين `isPremium=true` محلياً لتفعيل الميزات دون رد تحقق صالح.

## الفقاعة العائمة Android

تحتاج هذه الميزة Kotlin أصلياً داخل `android/`: خدمة foreground، `TYPE_APPLICATION_OVERLAY`، طلب `SYSTEM_ALERT_WINDOW` عبر `permission_handler`/MethodChannel، وحفظ موضع الفقاعة. تستقبل النص فقط عبر Share أو `ACTION_PROCESS_TEXT` الذي بدأه المستخدم؛ لا تقرأ WhatsApp أو البريد أو الإشعارات تلقائياً ولا تستخدم Accessibility Service.

## CI الصحيح في GitHub Actions

سيحل الملف التالي محل Workflow القديم عند تنفيذ الهجرة. لا يخلط Flutter مع Expo:

```yaml
name: Mirror Scorpion v4 Flutter APK
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.44.7"
          channel: stable
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: mirror-scorpion-v4-flutter-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
```

## ترتيب التنفيذ

يبدأ التنفيذ بمشروع Flutter نظيف وواجهة Royal Dark واللوحة الستية، ثم الترجمة والحوار والمستندات. تضاف القصص والإعدادات وPRO بعد تثبيت تخزين محلي وعقود API، ثم الفقاعة Kotlin، ثم الألعاب. يمنع ذلك إعادة أخطاء الحقن في Gradle أو البحث العشوائي عن إصدارات حزم.

## المراجع

[1]: https://pub.dev/packages/path_provider/versions "إصدارات path_provider المنشورة"
[2]: https://docs.flutter.dev/reference/supported-platforms "منصات Flutter المدعومة"
[3]: https://pub.dev/packages/flame_3d "Flame 3D — حالة الدعم التجريبي"
