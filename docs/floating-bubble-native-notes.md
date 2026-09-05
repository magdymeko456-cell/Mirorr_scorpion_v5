# تصميم الفقاعة العائمة الأصلية

## نطاق التنفيذ

المطلوب هو فقاعة Android حقيقية تظهر فوق نوافذ التطبيقات الأخرى، يستطيع المستخدم سحبها إلى موضع مناسب، والنقر عليها لفتح إجراء ترجمة للنص الذي يرسله المستخدم إلى الفقاعة عبر النسخ أو المشاركة. لا ينبغي للتطبيق قراءة محتوى البريد أو WhatsApp تلقائياً أو اعتراضه؛ ذلك يتطلب صلاحيات وصول مختلفة وحساسة، ويجب أن يظل خارج التفعيل الافتراضي.

## الحقائق التقنية

- Android يعرّف `TYPE_APPLICATION_OVERLAY` لنافذة تظهر فوق نوافذ التطبيقات، ويتطلب ذلك `Manifest.permission.SYSTEM_ALERT_WINDOW`.
- خدمة تعمل في الخلفية تحتاج عادة إلى Foreground Service مع إشعار دائم. على إصدارات Android الحديثة توجد قيود إضافية على بدء الخدمة من الخلفية؛ يجب اختبار APK/Dev Build حقيقي وليس Expo Go.
- توثيق Expo للوحدات المحلية يوصي بإنشاء مجلد `modules/<module>` يحوي Android وios وsrc و`expo-module.config.json`، ثم تشغيل `npx expo prebuild --clean` عند عدم وجود مشاريع أصلية.
- المشروع الحالي لا يحتوي مجلد Android أو iOS، لذلك لا يمكن اختبار Overlay داخل معاينة الويب أو Expo Go فقط. يلزم بناء أصلي بعد إضافة الوحدة.

## مسار الاستخدام الآمن

يفتح المستخدم التطبيق، يفعّل الفقاعة، يوافق على شاشة إعدادات Android الخاصة بالظهور فوق التطبيقات، ثم يحدد الموضع بالسحب. عند تحديد نص في البريد أو WhatsApp، يظهر Mirror Scorpion في قائمة **Process Text** أو **Share**؛ يرسل المستخدم النص صراحة إلى التطبيق، فيُفتح محرر الترجمة بالنص المحدد. كما يمكنه الضغط على الفقاعة من أي تطبيق لفتح الترجمة. لا يقرأ التطبيق محتوى البريد أو WhatsApp تلقائياً، ولا يستخدم Accessibility Service أو Notification Listener، ولا يخزن النص المشترك خارج المسار المعتاد إلا إذا طلب المستخدم ذلك.

## المراجع

- Expo Modules API: https://docs.expo.dev/modules/get-started/
- Android `TYPE_APPLICATION_OVERLAY`: https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY
- Android share/process-text intents: https://developer.android.com/training/sharing/send
- Android overlay permission: https://developer.android.com/reference/android/provider/Settings#canDrawOverlays(android.content.Context)
- Android foreground service changes: https://developer.android.com/develop/background-work/services/fgs/changes
