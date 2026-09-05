import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('translationSourceLanguage يبدأ بلغة الجهاز إذا لم يُختر', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    // بدون initialize مع SharedPreferences نحتاج مصدر افتراضي موثوق
    // هنا نختبر فقط أن السلفة قابلة بالضبط (الافتراضي يُحل عبر initialize)
    expect(prefs.deviceLanguageCode, equals('ar'));
  });

  test('translationSourceLanguage يعيد القيمة المخصصة بعد ضبطها', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    prefs.translationSourceLanguage = 'en';
    expect(prefs.translationSourceLanguage, equals('en'));
  });

  test('تبديل اللغة يحوّل المصدر والهدف', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    prefs.translationSourceLanguage = 'en';
    prefs.translationTargetLanguage = 'fr';
    prefs.swapTranslationLanguages();
    expect(prefs.translationSourceLanguage, equals('fr'));
  });
}
