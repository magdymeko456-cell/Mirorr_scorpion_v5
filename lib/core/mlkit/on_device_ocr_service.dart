import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum OnDeviceOcrState {
  recognized,
  empty,
  unsupportedPlatform,
  failed,
}

class OnDeviceOcrResult {
  const OnDeviceOcrResult({
    required this.state,
    this.text,
    this.message,
  });

  final OnDeviceOcrState state;
  final String? text;
  final String? message;

  bool get isSuccess => state == OnDeviceOcrState.recognized;
}

/// خدمة OCR محلية للصور فقط. يستخدم الإصدار الحالي محرك النص اللاتيني،
/// ولذلك لا يزعم قراءة العربية أو PDF قبل ربط محرك مناسب لهما.
class OnDeviceOcrService {
  const OnDeviceOcrService();

  static bool get isNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<OnDeviceOcrResult> recognizeImagePath(String path) async {
    if (!isNativePlatform) {
      return const OnDeviceOcrResult(
        state: OnDeviceOcrState.unsupportedPlatform,
        message: 'OCR المحلي متاح على Android وiOS فقط.',
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(InputImage.fromFilePath(path));
      final text = recognized.text.trim();
      if (text.isEmpty) {
        return const OnDeviceOcrResult(
          state: OnDeviceOcrState.empty,
          message: 'لم يعثر المحرك المحلي على نص لاتيني واضح في الصورة.',
        );
      }
      return OnDeviceOcrResult(
        state: OnDeviceOcrState.recognized,
        text: text,
        message: 'تم استخراج النص محلياً من الصورة. لم تتم ترجمة المستند بعد.',
      );
    } catch (_) {
      return const OnDeviceOcrResult(
        state: OnDeviceOcrState.failed,
        message: 'تعذر تحليل الصورة محلياً. جرّب صورة أوضح أو أعد المحاولة.',
      );
    } finally {
      await recognizer.close();
    }
  }
}
