# ملاحظات تكامل Stripe

## نتائج الوثائق الرسمية

1. توثيق Stripe للاشتراكات يوصي ببناء دورة اشتراك كاملة تشمل Checkout وBilling وWebhooks لإدارة الإنشاء والتجديد والفشل والإلغاء: https://docs.stripe.com/subscriptions
2. صفحة Stripe لمدفوعات السلع الرقمية تميز بين مسارات iOS وAndroid. في بعض حالات السلع الرقمية على iOS يكون Checkout الخارجي مقيداً بالولايات المتحدة، بينما يتيح Android في الولايات المتحدة معالجة Stripe داخل التطبيق؛ لذلك لا يجوز افتراض أن Stripe Checkout الخارجي مقبول لكل متجر أو دولة: https://docs.stripe.com/mobile/digital-goods
3. Webhook يجب أن يتحقق من ترويسة Stripe-Signature قبل تحديث حالة PRO، ولا يجوز اعتبار عودة المستخدم من Checkout دليلاً كافياً على الدفع: https://docs.stripe.com/webhooks

## قرار المشروع

سنستخدم Stripe Checkout للاختبار والويب/التوزيع المباشر، مع إنشاء جلسة اشتراك من الخادم وعدم وضع المفتاح السري في تطبيق Expo. سيحفظ الخادم معرف العميل والاشتراك وحالة PRO بعد التحقق من Webhook. قبل نشر نسخة iOS/Android في المتاجر، يجب مراجعة سياسة المتجر وتحديد ما إذا كان يلزم استخدام Apple/Google In-App Purchase أو مسار Stripe المتاح قانونياً للمنطقة.

## بيانات مطلوبة

- STRIPE_SECRET_KEY: مفتاح الخادم السري، يبدأ عادة بـ sk_test_ أو sk_live_.
- STRIPE_WEBHOOK_SECRET: سر توقيع Webhook، يبدأ عادة بـ whsec_.
- STRIPE_PRO_MONTHLY_PRICE_ID: معرف سعر شهري recurring من Stripe، يبدأ عادة بـ price_.
- STRIPE_PRO_YEARLY_PRICE_ID: معرف سعر سنوي recurring من Stripe، يبدأ عادة بـ price_.
