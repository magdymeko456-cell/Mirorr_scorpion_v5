# بوابات الخدمات الخارجية — مراجع رسمية

> **الغرض:** حفظ النتائج الخارجية التي تحكم قرارات الصوت وML Kit والفقاعة وPRO. لا يعني وجود خدمة أو توثيق أنها مفعلة في التطبيق.

| المجال | نتيجة مرجعية ذات أثر مباشر | القرار لمشروع Mirror Scorpion |
|---|---|---|
| ترجمة ML Kit على الجهاز | يدعم ML Kit أكثر من 50 لغة، يعمل على الجهاز، ويستخدم الإنجليزية وسيطاً بين لغتين غير إنجليزيتين؛ توصي Google بتقييم الجودة واستعمال Cloud Translation للحالات الأعلى دقة. | لا يُسوَّق كترجمة احترافية مضمونة لـ100 لغة. تبقى رسالة حدود الزوج اللغوي ومرحلة تنزيل النموذج صريحة. |
| تفريغ ملفات صوت طويلة | الملفات الأطول من دقيقة تستخدم batch غير متزامن، ويجب أن تكون في Cloud Storage، مع تتبع `Operation` حتى إتمامها. كما يلزم تمكين الفوترة والـAPI وأدوار IAM المناسبة. | لا يفعل دبوس الصوت تفريغاً حقيقياً قبل عقد upload/job/status/delete وموافقة تكلفة ومدة حفظ وحذف. |
| تكلفة Speech-to-Text | تسعير Speech-to-Text حسب دقائق الصوت المعالجة، كما تتحمل Storage والخدمات المصاحبة تكلفتها منفصلة. | لا توجد «ترجمة ملفات بلا حدود» قبل ميزانية وسياسة استخدام وسقف واضحين. |
| Firebase والخدمات الخلفية | Cloud Functions وStorage وخدمات Google تتبع حدوداً وأسعاراً بحسب الخطة والاستهلاك. | لا نشر Functions/Storage للإنتاج أو حفظ ملفات مستخدمين قبل تأكيد الفوترة وسياسة البيانات. |
| Overlay والـForeground Service | Android 14+ يفرض نوع الخدمة والأذونات المناسبة. Android 15+ يشترط وجود overlay مرئي مع `SYSTEM_ALERT_WINDOW` لبدء FGS من الخلفية في هذا المسار، وخدمات الميكروفون لا تبدأ في الخلفية بلا حالة/استثناء صالح. | تُبنى الفقاعة كوحدة Android أصلية مع إذن صريح، إشعار FGS، وحالات رفض واضحة. لا تستخدم Accessibility أو Notification Listener أو مراقبة الرسائل. |
| Share/Intents | `ACTION_SEND` هو مسار Android القياسي لمشاركة محتوى يختاره المستخدم مع تطبيق آخر؛ مكونات الخدمات الداخلية يجب أن تبدأ بـexplicit intent. | إدخال الفقاعة يقتصر على Share/Process Text أو كتابة المستخدم، مع تطهير/تحقق من extras وعدم تمرير intents متداخلة بلا فحص. |
| Google Play Billing | توصي Google بدمج تطبيق Android مع backend آمن للتحقق من المشتريات وحالات الاشتراك وRTDN؛ اعتباراً من 31 أغسطس 2026 تحتاج التطبيقات/التحديثات الجديدة إلى Billing Library 8 أو أحدث. | لا يكفي باتش محلي أو ID جهاز. عند قرار PRO: Play Billing + backend entitlement + وقت خادم + مزامنة/إبطال + اختبارات Sandbox. |
| حماية النسخة والدفع | Play Integrity يساعد backend على تقييم أصالة التطبيق والجهاز، لكنه جزء من استراتيجية متعددة الطبقات وليس بديلاً عن تحقق الخادم. | يستخدم لاحقاً قرب الإجراءات الحساسة فقط، مع تعامل متدرج للأخطاء وعدم تخزين verdicts كترخيص دائم. |

## المصادر

1. [ML Kit Translation](https://developers.google.com/ml-kit/language/translation) — تم التحديث في 19 أغسطس 2026.
2. [Cloud Speech-to-Text: Batch recognition](https://docs.cloud.google.com/speech-to-text/docs/batch-recognize) — ملفات طويلة، Cloud Storage، IAM، وفوترة.
3. [Cloud Speech-to-Text pricing](https://cloud.google.com/speech-to-text/pricing) — عوامل التكلفة والصوت وCloud Storage.
4. [Firebase pricing](https://firebase.google.com/pricing) — حدود وتسعير Functions وStorage.
5. [Android foreground-service changes](https://developer.android.com/develop/background-work/services/fgs/changes) — متطلبات Android 14–16.
6. [Foreground-service background-start restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start) — قيود الخلفية و`SYSTEM_ALERT_WINDOW`.
7. [Android intents and intent filters](https://developer.android.com/guide/components/intents-filters) — `ACTION_SEND` وexplicit intents.
8. [Google Play Billing](https://developer.android.com/google/play/billing) و[backend integration](https://developer.android.com/google/play/billing/backend) — تحقق المشتريات وRTDN.
9. [Play Integrity overview](https://developer.android.com/google/play/integrity/overview) — حماية متعددة الطبقات وتحقق backend.
