import 'package:flutter/foundation.dart';

class RunwareVideoPreflight {
  const RunwareVideoPreflight({
    required this.allowed,
    required this.code,
    required this.message,
  });

  final bool allowed;
  final String code;
  final String message;
}

/// حالة خطة الخدمات السحابية المعروضة للمستخدم.
/// لا تمثل اشتراكاً مشتَرى أو خدمة إنتاجية مفعّلة.
abstract final class SubscriptionBoundaries {
  static const localPlan = 'الأساسي المحلي';
  static const signedProPlan = 'PRO الموقّع';
  static const cloudVideoPlan = 'فيديو Runware السحابي';
  static const audioStudioPlan = 'استوديو الصوت';
  static const cloudVideoLimit = '0 مقطع يومياً حتى يعتمد المالك خطة ومفتاحاً وحداً مالياً.';
}

/// واجهة Runware في التطبيق لا تتصل بالشبكة ولا تحتوي مفتاحاً.
/// يتصل الخادم فقط بعد اعتماد سقف الإنفاق والموافقة والمفتاح الخادمي.
class RunwareVideoService extends ChangeNotifier {
  static const providerName = 'Runware';
  static const deliveryMethod = 'async';
  static const outputFormat = 'MP4';
  static const maxTrialDurationSeconds = 5;

  bool get enabled => false;
  bool get externalCallsAllowed => false;

  String get statusMessage =>
      'Runware مختار كمزود فيديو مستقبلي، لكنه مغلق الآن: لا رصيد، '
      'لا مفتاح، لا حصة، ولا تُرسل قصة أو صورة خارج الجهاز.';

  RunwareVideoPreflight prepareStoryVideo({
    required String draft,
    required bool hasExplicitConsent,
  }) {
    if (draft.trim().isEmpty) {
      return const RunwareVideoPreflight(
        allowed: false,
        code: 'STORY_REQUIRED',
        message: 'اكتب مسودة القصة أولاً قبل طلب فيديو.',
      );
    }
    if (!hasExplicitConsent) {
      return const RunwareVideoPreflight(
        allowed: false,
        code: 'CONSENT_REQUIRED',
        message: 'أكّد موافقتك الصريحة على إرسال النص المختار إلى Runware مستقبلاً قبل أي خدمة فيديو.',
      );
    }
    return RunwareVideoPreflight(
      allowed: false,
      code: 'GATEWAY_DISABLED',
      message: '$statusMessage ${SubscriptionBoundaries.cloudVideoLimit}',
    );
  }
}
