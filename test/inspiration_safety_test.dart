import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/inspiration/inspiration_safety.dart';

void main() {
  group('InspirationSafety', () {
    test('routes clear crisis wording to immediate human help', () {
      final result = InspirationSafety.assessMoodText('لا أريد أن أعيش اليوم');

      expect(result.level, InspirationSafetyLevel.crisis);
      expect(result.message, contains('خدمات الطوارئ'));
    });

    test('keeps ordinary opt-in mood input supportive', () {
      final result = InspirationSafety.assessMoodText('أحتاج إلى بداية هادئة اليوم');

      expect(result.level, InspirationSafetyLevel.supportive);
      expect(result.message, contains('لا توجد مراقبة'));
    });

    test('blocks a story draft containing a disallowed cue', () {
      final result = InspirationSafety.assessStoryDraft('هذه قصة فيها تنمر على شخص آخر');

      expect(result.allowedForDraft, isFalse);
    });
  });
}
