import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'system_tts_service.dart';

class TranslatedAudioFile {
  const TranslatedAudioFile({required this.path, required this.languageCode});
  final String path;
  final String languageCode;
}

class TranslatedAudioExportResult {
  const TranslatedAudioExportResult._({required this.message, this.audioFile});
  const TranslatedAudioExportResult.success(TranslatedAudioFile audioFile)
      : this._(message: 'تم إنشاء ملف WAV محلياً من النص المترجم.', audioFile: audioFile);
  const TranslatedAudioExportResult.failure(String message) : this._(message: message);
  final String message;
  final TranslatedAudioFile? audioFile;
  bool get isSuccess => audioFile != null;
}

/// يستعمل Android TTS لإنشاء ملف من نص مترجم موجود. لا يمثل نسخ صوت مستخدم
/// ولا يشارك ملفاً قبل فحص وجوده وحجمه.
class TranslatedAudioExportService {
  TranslatedAudioExportService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;

  static String fileNameFor(DateTime time) =>
      'mirror-scorpion-translated-${time.millisecondsSinceEpoch}.wav';
  static bool isWavPath(String path) => path.toLowerCase().endsWith('.wav');

  Future<TranslatedAudioExportResult> createWav({
    required String text,
    required String languageCode,
    required SystemVoiceProfile profile,
    SystemTtsVoice? selectedVoice,
  }) async {
    final content = text.trim();
    if (content.isEmpty) return const TranslatedAudioExportResult.failure('لا يوجد نص مترجم لإنشاء ملف صوتي.');
    final locale = _localeFor(languageCode);
    try {
      if (await _tts.isLanguageAvailable(locale) != true) {
        return TranslatedAudioExportResult.failure('صوت النظام للغة $locale غير متاح. نزّل صوتاً لهذه اللغة من إعدادات الهاتف.');
      }
      final cache = await getTemporaryDirectory();
      final directory = Directory('${cache.path}/mirror_scorpion/translated_audio');
      if (!await directory.exists()) await directory.create(recursive: true);
      final file = File('${directory.path}/${fileNameFor(DateTime.now())}');
      await _tts.awaitSynthCompletion(true);
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(profile.speechRate);
      await _tts.setPitch(profile.pitch);
      if (selectedVoice != null && selectedVoice.supportsLocale(locale)) {
        await _tts.setVoice(selectedVoice.toPlatformMap());
      } else {
        await _tts.clearVoice();
      }
      final result = await _tts.synthesizeToFile(content, file.path, true);
      if (result != 1 || !await file.exists() || await file.length() == 0) {
        if (await file.exists()) await file.delete();
        return const TranslatedAudioExportResult.failure('لم ينشئ صوت النظام ملف WAV صالحاً للنص المحدد.');
      }
      return TranslatedAudioExportResult.success(TranslatedAudioFile(path: file.path, languageCode: languageCode));
    } catch (_) {
      return const TranslatedAudioExportResult.failure('تعذر إنشاء ملف الصوت المحلي. تحقق من دعم صوت النظام للغة المحددة.');
    }
  }

  Future<TranslatedAudioExportResult> share(TranslatedAudioFile audioFile) async {
    final file = File(audioFile.path);
    if (!isWavPath(audioFile.path) || !await file.exists() || await file.length() == 0) {
      return const TranslatedAudioExportResult.failure('لا يوجد ملف صوت مترجم صالح لمشاركته. أنشئ الملف أولاً.');
    }
    try {
      await Share.shareXFiles(
        <XFile>[XFile(audioFile.path, mimeType: 'audio/wav')],
        subject: 'Mirror Scorpion — ترجمة صوتية',
        text: 'ملف صوتي مترجم محلياً بواسطة Mirror Scorpion.',
      );
      return TranslatedAudioExportResult.success(audioFile);
    } catch (_) {
      return const TranslatedAudioExportResult.failure('تعذر فتح واجهة مشاركة ملف الصوت.');
    }
  }

  Future<void> delete(TranslatedAudioFile? audioFile) async {
    if (audioFile == null) return;
    final file = File(audioFile.path);
    if (await file.exists()) await file.delete();
  }

  String _localeFor(String code) => switch (code.toLowerCase()) {
        'ar' => 'ar-SA', 'en' => 'en-US', 'fr' => 'fr-FR', 'es' => 'es-ES',
        'de' => 'de-DE', 'pt' => 'pt-PT', 'zh' => 'zh-CN', 'ja' => 'ja-JP',
        'ko' => 'ko-KR', 'ru' => 'ru-RU', 'tr' => 'tr-TR', _ => code,
      };
}
