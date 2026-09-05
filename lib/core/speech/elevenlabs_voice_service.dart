import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حالة تكامل ElevenLabs. السياسة: لا سر مضمّن في APK إطلاقاً — المفتاح
/// يدخله المالك وقت التشغيل ويُحفظ محلياً في SharedPreferences فقط.
enum ElevenLabsGatewayState {
  disabledPendingServerApproval,
  missingRuntimeKey,
  readyWithRuntimeKey,
}

class ElevenLabsVoiceAttempt {
  const ElevenLabsVoiceAttempt({
    required this.allowed,
    required this.message,
    this.audioPath,
    this.voiceId,
  });

  final bool allowed;
  final String message;
  final String? audioPath;
  final String? voiceId;

  bool get isSuccess => audioPath?.trim().isNotEmpty == true;
}

class ElevenLabsVoiceService extends ChangeNotifier {
  static const consentDocumentPath =
      'docs/elevenlabs-voice-consent-and-deletion-contract-2026-08-25.md';

  static const String _baseUrl = 'https://api.elevenlabs.io';
  static const String _runtimeKeyStoreKey =
      'mirror_scorpion_elevenlabs_runtime_key';
  static const String _clonedVoiceIdStoreKey =
      'mirror_scorpion_elevenlabs_cloned_voice_id';
  static const String _clonedVoiceName = 'mirror_scorpion_owner';
  static const String _ttsModelId = 'eleven_multilingual_v2';
  static const int maxSampleBytes = 25 * 1024 * 1024;

  final http.Client _client = http.Client();
  String? _runtimeKey;
  String? _clonedVoiceId;
  String? _message;
  bool _busy = false;
  ElevenLabsGatewayState _state =
      ElevenLabsGatewayState.disabledPendingServerApproval;

  ElevenLabsGatewayState get state => _state;
  bool get isGatewayEnabled =>
      _state == ElevenLabsGatewayState.readyWithRuntimeKey;
  bool get isBusy => _busy;
  bool get hasClonedVoice => _clonedVoiceId?.trim().isNotEmpty == true;
  String? get message => _message;

  String get statusMessage => _message ?? switch (_state) {
        ElevenLabsGatewayState.disabledPendingServerApproval =>
          'الربط السحابي معطّل حالياً. لا يُرسل التطبيق نصاً أو تسجيلاً إلى أي خدمة.',
        ElevenLabsGatewayState.missingRuntimeKey =>
          'أدخل مفتاح ElevenLabs الخاص بك ليُحفظ محلياً على جهازك فقط.',
        ElevenLabsGatewayState.readyWithRuntimeKey =>
          'الربط مفعّل بمفتاح دخلته يدوياً — محفوظ على جهازك فقط.',
      };

  Future<void> restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _runtimeKey = preferences.getString(_runtimeKeyStoreKey);
      _clonedVoiceId = preferences.getString(_clonedVoiceIdStoreKey);
      _state = (_runtimeKey?.trim().isNotEmpty ?? false)
          ? ElevenLabsGatewayState.readyWithRuntimeKey
          : ElevenLabsGatewayState.disabledPendingServerApproval;
    } catch (_) {
      _state = ElevenLabsGatewayState.missingRuntimeKey;
    }
    notifyListeners();
  }

  Future<bool> saveRuntimeKey(String input) async {
    final key = input.trim();
    if (key.length < 20 || RegExp(r'\s').hasMatch(key)) {
      _state = ElevenLabsGatewayState.missingRuntimeKey;
      _message = 'المفتاح غير صالح. الصق المفتاح كاملاً بلا مسافات.';
      notifyListeners();
      return false;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_runtimeKeyStoreKey, key);
      _runtimeKey = key;
      _state = ElevenLabsGatewayState.readyWithRuntimeKey;
      _message = 'حُفظ المفتاح محلياً. لن يُضمَّن في APK.';
      notifyListeners();
      return true;
    } catch (_) {
      _message = 'تعذر حفظ المفتاح محلياً.';
      notifyListeners();
      return false;
    }
  }

  Future<void> clearRuntimeKey() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_runtimeKeyStoreKey);
    } catch (_) {}
    _runtimeKey = null;
    _state = ElevenLabsGatewayState.missingRuntimeKey;
    _message = 'أُزيل المفتاح. لن يُرسل أي طلب إلى الخدمة.';
    notifyListeners();
  }

  Future<ElevenLabsVoiceAttempt> uploadVoiceSample({
    required String filePath,
  }) async {
    if (!isGatewayEnabled) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'أدخل مفتاح ElevenLabs أولاً.',
      );
    }
    final sample = File(filePath);
    if (!await sample.exists()) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'ملف العينة غير موجود. سجّلها من جديد.',
      );
    }
    if (await sample.length() > maxSampleBytes) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'العينة أكبر من الحد (25MB). سجّل 10–30 ثانية.',
      );
    }
    _busy = true;
    _message = 'جارٍ رفع العينة وإنشاء نسخة صوتك…';
    notifyListeners();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/v1/voices/add'),
      )
        ..headers['xi-api-key'] = _runtimeKey!
        ..fields['name'] = _clonedVoiceName
        ..fields['remove_background_noise'] = 'true'
        ..files.add(
          await http.MultipartFile.fromPath('files', sample.path),
        );
      final response =
          await http.Response.fromStream(await _client.send(request))
              .timeout(const Duration(seconds: 120));
      if (response.statusCode != 200) {
        _message =
            'تعذّر إنشاء النسخة. رمز الاستجابة ${response.statusCode}. تحقق من صلاحية المفتاح وحد الاستخدام.';
        return ElevenLabsVoiceAttempt(allowed: false, message: _message!);
      }
      final decoded = jsonDecode(response.body);
      final voiceId =
          decoded is Map<String, dynamic> ? decoded['voice_id'] as String? : null;
      if (voiceId == null || voiceId.isEmpty) {
        _message = 'لم تُعد الخدمة معرّف صوت صالحاً.';
        return ElevenLabsVoiceAttempt(allowed: false, message: _message!);
      }
      _clonedVoiceId = voiceId;
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_clonedVoiceIdStoreKey, voiceId);
      } catch (_) {}
      _message = 'تم إنشاء نسخة صوتك. استخدم زر القراءة لسماعها.';
      return ElevenLabsVoiceAttempt(allowed: true, message: _message!, voiceId: voiceId);
    } catch (_) {
      _message = 'تعذر رفع العينة. تحقق من الاتصال ثم أعد المحاولة.';
      return ElevenLabsVoiceAttempt(allowed: false, message: _message!);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<ElevenLabsVoiceAttempt> requestCloudReading({
    required String text,
    required String languageCode,
  }) async {
    final content = text.trim();
    if (content.isEmpty) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'لا يوجد نص لإرساله إلى القراءة السحابية.',
      );
    }
    if (!isGatewayEnabled) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'أدخل مفتاح ElevenLabs أولاً. لم يُرسل النص إلى الخدمة.',
      );
    }
    if (!hasClonedVoice) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'أنشئ نسخة صوتك أولاً من زر «صوتي» ثم أعد المحاولة.',
      );
    }
    _busy = true;
    _message = 'جارٍ توليد القراءة بصوتك المستنسخ…';
    notifyListeners();
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/text-to-speech/$_clonedVoiceId'),
            headers: <String, String>{
              'xi-api-key': _runtimeKey!,
              'Content-Type': 'application/json',
              'Accept': 'audio/mpeg',
            },
            body: jsonEncode(<String, dynamic>{
              'text': content,
              'model_id': _ttsModelId,
              'voice_settings': <String, double>{
                'stability': 0.5,
                'similarity_boost': 0.75,
              },
            }),
          )
          .timeout(const Duration(seconds: 120));
      if (response.statusCode != 200) {
        _message = 'تعذر توليد الصوت. رمز الاستجابة ${response.statusCode}.';
        return ElevenLabsVoiceAttempt(allowed: false, message: _message!);
      }
      final temp = await getTemporaryDirectory();
      final audioFile = File(
        '${temp.path}/mirror_scorpion/clone_${DateTime.now().microsecondsSinceEpoch}.mp3',
      );
      await audioFile.writeAsBytes(response.bodyBytes);
      _message = 'اكتمل توليد القراءة بصوتك المستنسخ.';
      return ElevenLabsVoiceAttempt(
        allowed: true,
        message: _message!,
        audioPath: audioFile.path,
      );
    } catch (_) {
      _message = 'تعذر الاتصال بخدمة القراءة السحابية. تحقق من الإنترنت.';
      return ElevenLabsVoiceAttempt(allowed: false, message: _message!);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<ElevenLabsVoiceAttempt> requestInstantVoiceClone() async {
    return const ElevenLabsVoiceAttempt(
      allowed: false,
      message:
          'لن يُرفع أي تسجيل تلقائياً. سجّل عينة صوتك (10–30 ثانية) من شريط الأصوات، ثم ارفعها فقط بعد موافقتك الصريحة ومن نفس الشاشة.',
    );
  }

  Future<bool> deleteClonedVoice() async {
    if (!hasClonedVoice) return true;
    try {
      await _client.delete(
        Uri.parse('$_baseUrl/v1/voices/$_clonedVoiceId'),
        headers: <String, String>{'xi-api-key': _runtimeKey ?? ''},
      );
      _clonedVoiceId = null;
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_clonedVoiceIdStoreKey);
      _message = 'حُذفت النسخة الصوتية من الخدمة ومن هذا الجهاز.';
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
