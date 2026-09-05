import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحتفظ بلغة مصدر الترجمة ولغة الهدف مع افتراضي مشتق من لغة الجهاز.
/// لغة المصدر هي لغة مربع الميكروفون ويمكن للمستخدم تغييرها وحفظها.
class LanguagePreferences extends ChangeNotifier {
  static const _sourceKey = 'mirror_scorpion_source_language';
  static const _legacySourceKey = 'mirror_scorpion_translation_source';
  static const _targetKey = 'mirror_scorpion_translation_target';

  LanguagePreferences({Locale? deviceLocale})
      : _deviceLocale = deviceLocale ?? PlatformDispatcher.instance.locale,
        _sourceLanguage = (deviceLocale ?? PlatformDispatcher.instance.locale)
            .languageCode
            .toLowerCase();

  final Locale _deviceLocale;
  late SharedPreferences _preferences;
  late String _targetLanguage = 'en';
  String _sourceLanguage;
  bool _isInitialized = false;

  Locale get deviceLocale => _deviceLocale;
  String get deviceLanguageCode => _deviceLocale.languageCode.toLowerCase();
  String get translationSourceLanguage => _sourceLanguage;
  String get translationTargetLanguage => _targetLanguage;
  String get storyLanguageCode => deviceLanguageCode;

  set translationSourceLanguage(String code) {
    final normalized = code.toLowerCase();
    if (_sourceLanguage == normalized) return;
    _sourceLanguage = normalized;
    notifyListeners();
  }

  set translationTargetLanguage(String code) {
    final normalized = code.toLowerCase();
    if (_targetLanguage == normalized) return;
    _targetLanguage = normalized;
    notifyListeners();
  }

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _isInitialized = true;
    await _preferences.remove(_legacySourceKey);
    _sourceLanguage = _preferences.getString(_sourceKey) ?? deviceLanguageCode;
    _targetLanguage = _preferences.getString(_targetKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setTranslationSourceLanguage(String code) async {
    translationSourceLanguage = code;
    if (_isInitialized) {
      await _preferences.setString(_sourceKey, _sourceLanguage);
    }
  }

  Future<void> setTranslationTargetLanguage(String code) async {
    translationTargetLanguage = code;
    if (_isInitialized) {
      await _preferences.setString(_targetKey, _targetLanguage);
    }
  }

  Future<void> swapTranslationLanguages() async {
    final oldSource = translationSourceLanguage;
    final oldTarget = translationTargetLanguage;
    translationSourceLanguage = oldTarget;
    translationTargetLanguage = oldSource;
    if (_isInitialized) {
      await _preferences.setString(_sourceKey, _sourceLanguage);
      await _preferences.setString(_targetKey, _targetLanguage);
    }
  }
}
