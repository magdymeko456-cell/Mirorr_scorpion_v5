# اختبار Cloud Functions لمشروع Mirror Scorpion v4

## نطاق المرحلة

تحتوي هذه المرحلة على دالة واحدة فقط: `healthCheck`. وهي تثبت أن هيكل Cloud Functions يعمل لمشروع Firebase `mirorr-d11b2` من دون ترجمة وهمية أو OCR أو مزود ذكاء اصطناعي أو تقييد PRO. تستخدم الدالة `initializeApp()` من دون وسيط، لذلك تعتمد على هوية Cloud Functions بدلاً من مفتاح محلي [1].

> لا تضف `serviceAccountKey.json` أو `test_firebase.js` إلى مجلد Flutter أو `functions/`. كلاهما محظور في `.gitignore` ولا يلزمان للتشغيل أو النشر.

| الملف | الغرض |
|---|---|
| `.firebaserc` | تحديد Firebase Project ID غير السري: `mirorr-d11b2`. |
| `firebase.json` | تعريف مجلد الدوال وNode.js 22 ومحاكي الاختبار. |
| `functions/index.js` | تهيئة Admin SDK بهوية بيئة التشغيل وتصدير `healthCheck`. |
| `functions/src/health.js` | منطق استجابة قابل للاختبار بلا شبكة. |
| `functions/test/` | اختبارات تحميل نقطة الدخول وبنية الاستجابة. |

## اختبار Termux

```bash
npm install -g firebase-tools
firebase login
cd ~/mirror_scorpion_v4/functions
npm install
npm run verify
cd ..
firebase emulators:start --only functions
```

في جلسة ثانية:

```bash
curl -sS -X POST \
  -H "Content-Type: application/json" \
  -d '{"data":{}}' \
  "http://127.0.0.1:5001/mirorr-d11b2/us-central1/healthCheck"
```

## النشر الاختباري

بعد نجاح المحاكي فقط:

```bash
firebase deploy --only functions:healthCheck
```

يتطلب النشر خطة Blaze. لا ينفذ هذا المستودع أي تغيير فوترة أو نشر تلقائي. لا نربط Flutter أو نفعّل مزودات الترجمة وOCR والصوت حتى ينجح الاختبار المحلي ثم النشر الاختباري [2].

## المراجع

[1]: https://firebase.google.com/docs/functions/get-started "Get started with Cloud Functions for Firebase"
[2]: https://firebase.google.com/docs/functions/manage-functions "Manage functions"
