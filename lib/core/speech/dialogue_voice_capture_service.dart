import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class DialogueVoiceCaptureResult {
  const DialogueVoiceCaptureResult._({required this.message, this.filePath});
  const DialogueVoiceCaptureResult.success(String path)
      : this._(message: 'جارٍ التسجيل… اضغط المايك مرة أخرى للانتهاء.', filePath: path);
  const DialogueVoiceCaptureResult.failure(String message) : this._(message: message);

  final String message;
  final String? filePath;
  bool get isSuccess => filePath != null;
}

/// يسجّل صوت الحوار محلياً إلى WAV أحادي القناة بمعدل 16kHz
/// بما يناسب محرك Whisper مباشرة دون أي خدمة سحابية.
class DialogueVoiceCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _activePath;

  bool get isRecording => _activePath != null;

  Future<DialogueVoiceCaptureResult> start() async {
    if (_activePath != null) {
      return const DialogueVoiceCaptureResult.failure('يوجد تسجيل جارٍ بالفعل. اضغط المايك مرة أخرى لإنهائه.');
    }
    try {
      if (!await _recorder.hasPermission()) {
        return const DialogueVoiceCaptureResult.failure('رُفض إذن الميكروفون. امنح التطبيق الإذن من إعدادات الجهاز.');
      }
      final temp = await getTemporaryDirectory();
      final directory = Directory('${temp.path}/mirror_scorpion/dialogue');
      if (!await directory.exists()) await directory.create(recursive: true);
      final path = '${directory.path}/dialogue_${DateTime.now().microsecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: path,
      );
      _activePath = path;
      return DialogueVoiceCaptureResult.success(path);
    } catch (_) {
      _activePath = null;
      return const DialogueVoiceCaptureResult.failure('تعذر بدء تسجيل الصوت. أغلق تطبيقات تستخدم المايك ثم أعد المحاولة.');
    }
  }

  /// يعيد مسار الملف المسجل أو null إن لم يوجد تسجيل.
  Future<String?> stop() async {
    final path = _activePath;
    _activePath = null;
    if (path == null) return null;
    try {
      final stoppedPath = await _recorder.stop();
      return stoppedPath ?? (await File(path).exists() ? path : null);
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    if (_activePath != null) {
      try { await _recorder.stop(); } catch (_) {}
      _activePath = null;
    }
    try { await _recorder.dispose(); } catch (_) {}
  }
}
