import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/speech/device_speech_recognition_service.dart';

void main() {
  group('Speech recognizer restart policy', () {
    test('leaves Android time to release the previous microphone session', () {
      expect(
        DeviceSpeechRecognitionService.recognizerReleaseSettleTime,
        const Duration(milliseconds: 350),
      );
    });
  });

  group('SpeechLocaleResolver', () {
    test('matches a source language to an installed recognition locale', () {
      expect(
        SpeechLocaleResolver.preferredLocaleId(
          languageCode: 'ar',
          installedLocaleIds: const ['en_US', 'ar-EG'],
        ),
        'ar-EG',
      );
    });

    test('matches English speech to an installed regional locale', () {
      expect(
        SpeechLocaleResolver.preferredLocaleId(
          languageCode: 'en',
          installedLocaleIds: const ['ar_EG', 'en-US'],
        ),
        'en-US',
      );
    });

    test('lists unique installed language codes for an unavailable source', () {
      expect(
        SpeechLocaleResolver.availableLanguageCodes(
          const ['ar_EG', 'en-US', 'en_GB'],
        ),
        <String>['ar', 'en'],
      );
    });

    test('allows the device default when a matching locale is absent', () {
      expect(
        SpeechLocaleResolver.preferredLocaleId(
          languageCode: 'ar',
          installedLocaleIds: const ['en_US', 'fr-FR'],
        ),
        isNull,
      );
    });
  });

  group('SpeechRecognitionScriptGuard', () {
    test('rejects Arabic transliteration when English was requested', () {
      expect(
        SpeechRecognitionScriptGuard.rejectsArabicFallback(
          expectedLanguageCode: 'en',
          recognizedText: 'جود نايت',
        ),
        isTrue,
      );
    });

    test('accepts English text when English was requested', () {
      expect(
        SpeechRecognitionScriptGuard.rejectsArabicFallback(
          expectedLanguageCode: 'en',
          recognizedText: 'good night',
        ),
        isFalse,
      );
    });

    test('rejects Arabic transliteration for another Latin-script language', () {
      expect(
        SpeechRecognitionScriptGuard.rejectsArabicFallback(
          expectedLanguageCode: 'fr',
          recognizedText: 'بونجور',
        ),
        isTrue,
      );
    });
  });
}
