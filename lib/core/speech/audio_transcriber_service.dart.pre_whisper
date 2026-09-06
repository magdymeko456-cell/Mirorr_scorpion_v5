import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

enum AudioTranscriptionStage { preparing, transcribing, cleaning }
typedef AudioTranscriptionProgress = void Function(AudioTranscriptionStage stage, int? percent);

class AudioFileTranscriptionResult {
  const AudioFileTranscriptionResult._({required this.message, this.text});
  const AudioFileTranscriptionResult.success(String text)
      : this._(text: text, message: 'اكتمل تفريغ الملف محلياً. راجع النص قبل ترجمته أو مشاركته.');
  const AudioFileTranscriptionResult.failure(String message) : this._(message: message);

  final String message;
  final String? text;
  bool get isSuccess => text?.trim().isNotEmpty == true;
}

class AudioTranscriberService {
  bool _isProcessing = false;
  static const int maxInputBytes = 128 * 1024 * 1024;
  static const Set<String> supportedExtensions = <String>{'mp3', 'm4a', 'wav', 'ogg', 'aac', 'flac'};
  bool get isProcessing => _isProcessing;

  static bool supportsPath(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 && supportedExtensions.contains(name.substring(dot + 1).toLowerCase());
  }
  static bool allowsFileSize(int bytes) => bytes > 0 && bytes <= maxInputBytes;

  Future<AudioFileTranscriptionResult> transcribeAudioFile({
    required String filePath,
    required File verifiedModelFile,
    AudioTranscriptionProgress? onProgress,
  }) async {
    if (_isProcessing) return const AudioFileTranscriptionResult.failure('يوجد تفريغ محلي جارٍ بالفعل. انتظر اكتماله قبل اختيار ملف آخر.');
    final source = File(filePath);
    if (!await source.exists()) return const AudioFileTranscriptionResult.failure('لم يعد ملف الصوت المختار متاحاً.');
    if (!supportsPath(filePath)) return const AudioFileTranscriptionResult.failure('صيغة الملف غير مدعومة. اختر MP3 أو M4A أو WAV أو OGG أو AAC أو FLAC.');
    if (!allowsFileSize(await source.length())) return const AudioFileTranscriptionResult.failure('حجم الملف غير مناسب. الحد الأقصى للتفريغ المحلي هو 128 MB.');
    if (!await verifiedModelFile.exists()) return const AudioFileTranscriptionResult.failure('نموذج التفريغ المحلي غير موجود أو لم يكتمل التحقق منه.');

    _isProcessing = true;
    Directory? jobDirectory;
    try {
      onProgress?.call(AudioTranscriptionStage.preparing, null);
      final temp = await getTemporaryDirectory();
      jobDirectory = Directory('${temp.path}/mirror_scorpion/asr_${DateTime.now().microsecondsSinceEpoch}');
      await jobDirectory.create(recursive: true);
      final extension = filePath.split('.').last.toLowerCase();
      final workFile = File('${jobDirectory.path}/input.$extension');
      await source.copy(workFile.path);
      onProgress?.call(AudioTranscriptionStage.transcribing, 0);
      final response = await Whisper(model: WhisperModel.base).transcribe(
        transcribeRequest: TranscribeRequest(audio: workFile.path, isNoTimestamps: true, keepModelLoaded: false),
        modelPath: verifiedModelFile.path,
        onProgress: (value) => onProgress?.call(AudioTranscriptionStage.transcribing, value.clamp(0, 100).toInt()),
      );
      final text = response.text.trim();
      return text.isEmpty
          ? const AudioFileTranscriptionResult.failure('لم يعثر محرك التفريغ على كلام واضح داخل الملف. جرب تسجيلاً أوضح.')
          : AudioFileTranscriptionResult.success(text);
    } catch (error) {
      return AudioFileTranscriptionResult.failure(
        'تعذر تفريغ الملف محلياً. ${failureDetail(error)}',
      );
    } finally {
      onProgress?.call(AudioTranscriptionStage.cleaning, null);
      if (jobDirectory != null && await jobDirectory.exists()) await jobDirectory.delete(recursive: true);
      try { await const Whisper(model: WhisperModel.base).releaseModel(); } catch (_) {}
      _isProcessing = false;
    }
  }

  /// تلخّص خطأ المحرك من دون كشف المسارات المحلية، كي يستطيع المستخدم معرفة
  /// هل المشكلة من تحويل FFmpeg أو النموذج أو ملف الإدخال بدلاً من بقاء الواجهة
  /// عند رسالة الموافقة فقط.
  static String failureDetail(Object error) {
    final detail = error
        .toString()
        .replaceAll(RegExp(r'/(?:[^\s/]+/)+[^\s]+'), '[مسار محلي]')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (detail.isEmpty) return 'أعاد محرك الصوت خطأ غير مسمّى.';
    final limited = detail.length > 180 ? '${detail.substring(0, 180)}…' : detail;
    return 'تفاصيل المحرك: $limited';
  }
}
