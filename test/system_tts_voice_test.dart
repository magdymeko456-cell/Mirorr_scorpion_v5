import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/speech/system_tts_service.dart';

void main() {
  test('parses a valid platform voice map', () {
    final voice = SystemTtsVoice.fromPlatformMap(<String, dynamic>{
      'name': 'Arabic local voice',
      'locale': 'ar-SA',
    });

    expect(voice.name, 'Arabic local voice');
    expect(voice.supportsLocale('ar-EG'), isTrue);
    expect(voice.supportsLocale('en-US'), isFalse);
    expect(
      voice.toPlatformMap(),
      <String, String>{'name': 'Arabic local voice', 'locale': 'ar-SA'},
    );
  });

  test('rejects incomplete platform voice maps', () {
    expect(
      () => SystemTtsVoice.fromPlatformMap(<String, dynamic>{'name': 'voice'}),
      throwsFormatException,
    );
  });

  test('defines the five named local voice performance profiles', () {
    expect(SystemVoiceProfile.values, hasLength(5));
    expect(
      SystemVoiceProfile.values.map((profile) => profile.label),
      <String>['سلمى', 'سيف', 'سما', 'سارة', 'صوتي'],
    );
    expect(SystemVoiceProfile.salma.styleDescription, contains('هادئ'));
    expect(SystemVoiceProfile.saif.styleDescription, contains('جاد'));
    expect(SystemVoiceProfile.sama.styleDescription, contains('نشط'));
    expect(SystemVoiceProfile.sara.styleDescription, contains('مبهج'));
    expect(SystemVoiceProfile.myVoice.styleDescription, contains('معايرة'));
  });

  test('local performance profiles keep distinct rate and pitch settings', () {
    final namedProfiles = <SystemVoiceProfile>{
      SystemVoiceProfile.salma, SystemVoiceProfile.saif,
      SystemVoiceProfile.sama, SystemVoiceProfile.sara,
    };
    final rates = namedProfiles.map((p) => p.speechRate).toSet();
    final pitches = namedProfiles.map((p) => p.pitch).toSet();
    expect(rates, hasLength(4));
    expect(pitches, hasLength(4));
    expect(SystemVoiceProfile.saif.pitch, lessThan(1));
    expect(SystemVoiceProfile.sama.speechRate, greaterThan(0.5));
    // صوتي (المعاير محلياً) له قيماً داخل نطاق flutter_tts الآمن.
    expect(SystemVoiceProfile.myVoice.speechRate, inInclusiveRange(0.3, 0.7));
    expect(SystemVoiceProfile.myVoice.pitch, inInclusiveRange(0.5, 2.0));
  });
}
