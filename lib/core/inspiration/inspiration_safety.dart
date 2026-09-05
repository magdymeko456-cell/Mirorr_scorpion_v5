enum InspirationSafetyLevel { supportive, crisis }

class InspirationSafetyResult {
  const InspirationSafetyResult({
    required this.level,
    required this.message,
  });

  final InspirationSafetyLevel level;
  final String message;
}

/// فحص محلي أولي ومحدود. لا يشخّص الحالة النفسية ولا يراقب أي تطبيق أو
/// محتوى خارج ما يكتبه المستخدم صراحة في هذه الشاشة. يبقى الفحص الخادمي
/// المستقل شرطاً قبل إرسال أي طلب إلى نموذج ذكاء أو مولد فيديو.
class InspirationSafety {
  const InspirationSafety._();

  static InspirationSafetyResult assessMoodText(String text) {
    final normalized = text.toLowerCase();
    const crisisCues = [
      'انتحار',
      'اقتل نفسي',
      'أقتل نفسي',
      'انهي حياتي',
      'أنهي حياتي',
      'لا أريد أن أعيش',
      'لا اريد ان اعيش',
      'إيذاء نفسي',
      'ايذاء نفسي',
    ];
    if (crisisCues.any(normalized.contains)) {
      return const InspirationSafetyResult(
        level: InspirationSafetyLevel.crisis,
        message: 'يبدو أن ما كتبته قد يشير إلى خطر فوري. لست وحدك: تواصل الآن مع شخص موثوق قريب منك، واتصل بخدمات الطوارئ المحلية أو خط دعم الأزمات في بلدك. لا تعتمد على التطبيق وحده في هذه اللحظة.',
      );
    }
    return const InspirationSafetyResult(
      level: InspirationSafetyLevel.supportive,
      message: 'سيبقى ما تكتبه داخل هذه الجلسة المحلية إلى أن تختار بنفسك طلب مساعدة ذكية من خدمة منشورة. لا توجد مراقبة سلبية للتطبيقات أو الرسائل.',
    );
  }

  static StoryModerationResult assessStoryDraft(String text) {
    final normalized = text.toLowerCase();
    const disallowedCues = [
      'كراهية',
      'تنمر',
      'إهانة',
      'شتيمة',
      'بذيء',
      'جنسي',
    ];
    if (disallowedCues.any(normalized.contains)) {
      return const StoryModerationResult(
        allowedForDraft: false,
        message: 'لا يمكن تجهيز هذا النص للفيديو قبل إزالة الكراهية أو التنمر أو الإهانات أو المحتوى الجنسي أو الألفاظ البذيئة. سيُعاد فحصه خادمياً قبل أي توليد مستقبلي.',
      );
    }
    return const StoryModerationResult(
      allowedForDraft: true,
      message: 'اجتاز النص الفحص المحلي الأولي فقط. لن يُرسل إلى مولد فيديو حتى يوافق المستخدم وتتحقق خدمة الخادم من المحتوى والحقوق.',
    );
  }
}

class StoryModerationResult {
  const StoryModerationResult({
    required this.allowedForDraft,
    required this.message,
  });

  final bool allowedForDraft;
  final String message;
}
