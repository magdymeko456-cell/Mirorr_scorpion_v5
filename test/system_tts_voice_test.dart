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

  test('defines the four named local voice performance profiles', () {
    expect(SystemVoiceProfile.values, hasLength(4));
    expect(
      SystemVoiceProfile.values.map((profile) => profile.label),
      <String>['سلمى', 'سيف', 'سما', 'سارة'],
    );
    expect(SystemVoiceProfile.salma.styleDescription, contains('هادئ'));
    expect(SystemVoiceProfile.saif.styleDescription, contains('جاد'));
    expect(SystemVoiceProfile.sama.styleDescription, contains('نشط'));
    expect(SystemVoiceProfile.sara.styleDescription, contains('مبهج'));
  });

  test('local performance profiles keep distinct rate and pitch settings', () {
    final profiles = SystemVoiceProfile.values;
    final rates = profiles.map((profile) => profile.speechRate).toSet();
    final pitches = profiles.map((profile) => profile.pitch).toSet();

    expect(rates, hasLength(4));
    expect(pitches, hasLength(4));
    expect(SystemVoiceProfile.saif.pitch, lessThan(1));
    expect(SystemVoiceProfile.sama.speechRate, greaterThan(0.5));
  });
}
