# إعداد Firebase Admin الآمن لـMirror Scorpion v4

## القرار المعتمد

داخل Cloud Functions تُشغّل Firebase تطبيق Admin باستخدام `initializeApp()` من دون تمرير ملف حساب خدمة. تمنح بيئة Functions هوية تشغيل افتراضية؛ لذلك لا يُحفظ `serviceAccountKey.json` في Flutter أو GitHub أو مجلد الدوال [1].

```js
const { initializeApp } = require("firebase-admin/app");

initializeApp();
```

## حدود استخدام مفتاح حساب الخدمة

ملف حساب الخدمة يصلح لاختبار مسؤول خارجي على خادم موثوق فقط. لا يلزم لـCloud Functions، ولا يُضمّن في APK، ولا يُرفع إلى GitHub. إذا أنشئ للاختبار المحلي، يُزال من جذر المستودع بعد الاستخدام وتبقى قواعد `.gitignore` مانعة لتتبعه.

| البيئة | طريقة التهيئة | ملف حساب خدمة محلي |
|---|---|---|
| Cloud Functions | `initializeApp()` | غير مطلوب |
| Firebase Emulator | `initializeApp()` مع تحذير غياب إعداد المشروع عند عدم تسجيل الدخول | غير مطلوب لاختبار `healthCheck` |
| خادم خارجي موثوق | Application Default Credentials أو سر مُدار | لا يوضع في مستودع أو تطبيق |

## المراجع

[1]: https://firebase.google.com/docs/functions/get-started "Get started with Cloud Functions for Firebase"
