import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SystemSpeechState { idle, speaking, unavailable, failed }

/// ملفات أداء محلية تضبط سرعة وطبقة صوت Android المختار.
///
/// لا تمثل هذه الملفات أصواتاً بشرية مستقلة ولا تضمن جنساً أو نبرة ثابتة؛
/// فالنتيجة تعتمد على صوت النظام المثبت والمتوافق مع لغة النص في الجهاز.
enum SystemVoiceProfile {
  salma,
  saif,
  sama,
  sara;

  String get label => switch (this) {
        SystemVoiceProfile.salma => 'سلمى',
        SystemVoiceProfile.saif => 'سيف',
        SystemVoiceProfile.sama => 'سما',
        SystemVoiceProfile.sara => 'سارة',
      };

  String get styleDescription => switch (this) {
        SystemVoiceProfile.salma => 'أداء هادئ ولطيف',
        SystemVoiceProfile.saif => 'أداء جاد ومتزن',
        SystemVoiceProfile.sama => 'أداء نشط وحيوي',
        SystemVoiceProfile.sara => 'أداء مبهج ودافئ',
      };

  double get speechRate => switch (this) {
        SystemVoiceProfile.salma => 0.42,
        SystemVoiceProfile.saif => 0.40,
        SystemVoiceProfile.sama => 0.52,
        SystemVoiceProfile.sara => 0.48,
      };

  double get pitch => switch (this) {
        SystemVoiceProfile.salma => 1.02,
        SystemVoiceProfile.saif => 0.90,
        SystemVoiceProfile.sama => 1.12,
        SystemVoiceProfile.sara => 1.08,
      };
}

class SystemTtsVoice {
  const SystemTtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  factory SystemTtsVoice.fromPlatformMap(Map<dynamic, dynamic> value) {
    final name = value['name'];
    final locale = value['locale'];
    if (name is! String || name.trim().isEmpty ||
        locale is! String || locale.trim().isEmpty) {
      throw const FormatException('Invalid system TTS voice.');
    }
    return SystemTtsVoice(name: name, locale: locale);
  }

  bool supportsLocale(String requestedLocale) =>
      _languagePart(locale) == _languagePart(requestedLocale);

  Map<String, String> toPlatformMap() => <String, String>{
        'name': name,
        'locale': locale,
      };

  @override
  bool operator ==(Object other) =>
      other is SystemTtsVoice && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);

  static String _languagePart(String locale) =>
      locale.replaceAll('_', '-').split('-').first.toLowerCase();
}

class SystemTtsService extends ChangeNotifier {
  /// مفتاح اختياري يجعل ملف الأداء مستقلاً لكل كارت ويحفظه بين الجلسات.
  SystemTtsService({String? storageKey})
      : _tts = FlutterTts(),
        _storageKey = storageKey;

  final FlutterTts _tts;
  final String? _storageKey;
  SystemSpeechState _state = SystemSpeechState.idle;
  String? _message;
  SystemTtsVoice? _selectedVoice;
  SystemVoiceProfile _selectedProfile = SystemVoiceProfile.salma;

  SystemSpeechState get state => _state;
  String? get message => _message;
  bool get isSpeaking => _state == SystemSpeechState.speaking;
  SystemTtsVoice? get selectedVoice => _selectedVoice;
  SystemVoiceProfile get selectedProfile => _selectedProfile;

  Future<void> initialize() async {
    _tts.setStartHandler(() {
      _state = SystemSpeechState.speaking;
      _message = 'جارٍ النطق بصوت النظام…';
      notifyListeners();
    });
    _tts.setCompletionHandler(_markIdle);
    _tts.setCancelHandler(_markIdle);
    _tts.setErrorHandler((_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر تشغيل صوت النظام للنص المحدد.';
      notifyListeners();
    });
    await _restoreSavedProfile();
    await _applyProfile();
  }

  Future<void> _restoreSavedProfile() async {
    if (_storageKey == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved =
          preferences.getString('mirror_scorpion_voice_profile_$_storageKey');
      final matches = SystemVoiceProfile.values
          .where((profile) => profile.name == saved)
          .toList();
      if (matches.isNotEmpty) _selectedProfile = matches.first;
    } catch (_) {
      // بلا تخزين متاح يبقى ملف الأداء الافتراضي.
    }
  }

  Future<bool> speak({required String text, required String languageCode}) async {
    final content = text.trim();
    if (content.isEmpty) {
      _state = SystemSpeechState.unavailable;
      _message = 'لا يوجد نص لقراءته.';
      notifyListeners();
      return false;
    }
    final locale = _localeFor(languageCode);
    try {
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true) {
        _state = SystemSpeechState.unavailable;
        _message = 'صوت النظام للغة $locale غير متاح على هذا الجهاز.';
        notifyListeners();
        return false;
      }
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _applyProfile();
      final voice = _selectedVoice;
      if (voice != null && voice.supportsLocale(locale)) {
        await _tts.setVoice(voice.toPlatformMap());
      } else if (voice != null) {
        await _tts.clearVoice();
      }
      final result = await _tts.speak(content, focus: true);
      if (result == 1) return true;
      _state = SystemSpeechState.failed;
      _message = 'لم يبدأ صوت النظام. جرّب تنزيل صوت لهذه اللغة من إعدادات الجهاز.';
      notifyListeners();
      return false;
    } catch (_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر تهيئة صوت النظام للغة المطلوبة.';
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _markIdle();
  }

  Future<List<SystemTtsVoice>> voicesForLanguage(String languageCode) async {
    final requestedLocale = _localeFor(languageCode);
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return const <SystemTtsVoice>[];
      final voices = <SystemTtsVoice>[];
      for (final rawVoice in rawVoices) {
        if (rawVoice is! Map) continue;
        try {
          final voice = SystemTtsVoice.fromPlatformMap(rawVoice);
          if (voice.supportsLocale(requestedLocale)) voices.add(voice);
        } on FormatException {
          // محرك النظام قد يعيد سجلاً ناقصاً؛ لا نعرضه للمستخدم.
        }
      }
      voices.sort((left, right) => left.name.compareTo(right.name));
      return voices;
    } catch (_) {
      _message = 'تعذر قراءة قائمة أصوات النظام في هذا الجهاز.';
      notifyListeners();
      return const <SystemTtsVoice>[];
    }
  }

  Future<bool> selectVoice(
    SystemTtsVoice? voice, {
    required String languageCode,
  }) async {
    final requestedLocale = _localeFor(languageCode);
    if (voice != null && !voice.supportsLocale(requestedLocale)) {
      _state = SystemSpeechState.unavailable;
      _message = 'هذا الصوت لا يدعم لغة القصة الحالية.';
      notifyListeners();
      return false;
    }
    try {
      if (voice == null) {
        await _tts.clearVoice();
      } else {
        await _tts.setVoice(voice.toPlatformMap());
      }
      _selectedVoice = voice;
      _state = SystemSpeechState.idle;
      _message = voice == null
          ? 'سيستخدم التطبيق صوت النظام الافتراضي.'
          : 'تم اختيار صوت النظام: ${voice.name}.';
      notifyListeners();
      return true;
    } catch (_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر اختيار صوت النظام المطلوب.';
      notifyListeners();
      return false;
    }
  }

  Future<void> selectProfile(SystemVoiceProfile profile) async {
    _selectedProfile = profile;
    try {
      await _saveProfile(profile);
      await _applyProfile();
      _state = SystemSpeechState.idle;
      _message = 'تم اختيار ملف الأداء المحلي: ${profile.label} — '
          '${profile.styleDescription}. يعتمد الصوت الفعلي على صوت Android '
          'المثبت في جهازك.';
    } catch (_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر تطبيق ملف الأداء المحلي المطلوب على صوت النظام.';
    }
    notifyListeners();
  }

  Future<void> _saveProfile(SystemVoiceProfile profile) async {
    if (_storageKey == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'mirror_scorpion_voice_profile_$_storageKey',
        profile.name,
      );
    } catch (_) {
      // الحفظ اختياري؛ لا يفشل النطق إذا تعذر التخزين.
    }
  }

  void _markIdle() {
    _state = SystemSpeechState.idle;
    _message = null;
    notifyListeners();
  }

  Future<void> _applyProfile() async {
    await _tts.setSpeechRate(_selectedProfile.speechRate);
    await _tts.setPitch(_selectedProfile.pitch);
  }

  String _localeFor(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return 'ar-SA';
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'de':
        return 'de-DE';
      case 'pt':
        return 'pt-PT';
      case 'zh':
        return 'zh-CN';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'ru':
        return 'ru-RU';
      case 'tr':
        return 'tr-TR';
      default:
        return languageCode;
    }
  }
}
