import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses device language as a fixed microphone source and persists target only', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = LanguagePreferences(deviceLocale: const Locale('en', 'US'));

    await preferences.initialize();

    expect(preferences.translationSourceLanguage, 'en');
    expect(preferences.translationTargetLanguage, 'en');

    await preferences.setTranslationTargetLanguage('de');

    SharedPreferences.setMockInitialValues(<String, Object>{
      'mirror_scorpion_translation_source': 'fr',
      'mirror_scorpion_translation_target': 'de',
    });
    final restored = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    await restored.initialize();

    expect(restored.translationSourceLanguage, 'ar');
    expect(restored.translationTargetLanguage, 'de');
  });

  test('uses Turkish device language for microphone with English target by default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = LanguagePreferences(deviceLocale: const Locale('tr', 'TR'));

    await preferences.initialize();

    expect(preferences.translationSourceLanguage, 'tr');
    expect(preferences.translationTargetLanguage, 'en');
  });

  test('persists a user-selected microphone source language', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = LanguagePreferences(deviceLocale: const Locale('de', 'DE'));

    await preferences.initialize();
    await preferences.setTranslationSourceLanguage('fr');

    SharedPreferences.setMockInitialValues(<String, Object>{
      'mirror_scorpion_source_language': 'fr',
      'mirror_scorpion_translation_target': 'en',
    });
    final restored = LanguagePreferences(deviceLocale: const Locale('de', 'DE'));
    await restored.initialize();

    expect(restored.translationSourceLanguage, 'fr');
  });
}
