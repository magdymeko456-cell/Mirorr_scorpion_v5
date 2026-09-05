import 'dart:convert';
import 'dart:io';

import 'package:read_pdf_text/read_pdf_text.dart';

enum LocalDocumentKind { pdf, plainText, unsupported }

class LocalDocumentTextResult {
  const LocalDocumentTextResult({
    required this.isSuccess,
    required this.message,
    this.text,
  });

  final bool isSuccess;
  final String message;
  final String? text;
}

/// سياسة قسم المستندات: لغة جهاز المستخدم هي هدف الترجمة الوحيد.
abstract final class DocumentTranslationPolicy {
  static String targetForDevice(String deviceLanguageCode) =>
      deviceLanguageCode.trim().toLowerCase();
}

/// يستخرج نصاً مضمنًا في PDF أو ملف TXT محلياً.
/// لا يحوّل PDF المصوّر إلى نص ولا يرفع الملف خارج الجهاز.
class LocalDocumentTextService {
  const LocalDocumentTextService();

  static LocalDocumentKind kindForName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    if (normalized.endsWith('.pdf')) return LocalDocumentKind.pdf;
    if (normalized.endsWith('.txt')) return LocalDocumentKind.plainText;
    return LocalDocumentKind.unsupported;
  }

  Future<LocalDocumentTextResult> extract({
    required String path,
    required String fileName,
  }) async {
    if (path.trim().isEmpty) {
      return const LocalDocumentTextResult(
        isSuccess: false,
        message: 'تعذر فتح الملف محلياً. اختر ملفاً متاحاً من الجهاز ثم أعد المحاولة.',
      );
    }
    switch (kindForName(fileName)) {
      case LocalDocumentKind.plainText:
        return _extractPlainText(path);
      case LocalDocumentKind.pdf:
        return _extractPdfText(path);
      case LocalDocumentKind.unsupported:
        return const LocalDocumentTextResult(
          isSuccess: false,
          message: 'يدعم هذا الإصدار ملفات PDF النصية وTXT فقط.',
        );
    }
  }

  Future<LocalDocumentTextResult> _extractPlainText(String path) async {
    try {
      final text = utf8.decode(await File(path).readAsBytes()).trim();
      if (text.isEmpty) {
        return const LocalDocumentTextResult(
          isSuccess: false,
          message: 'ملف النص فارغ أو لا يحتوي على نص قابل للترجمة.',
        );
      }
      return LocalDocumentTextResult(
        isSuccess: true,
        text: text,
        message: 'تمت قراءة ملف النص محلياً. جارٍ اكتشاف لغته وترجمته إلى لغة جهازك…',
      );
    } on FileSystemException {
      return const LocalDocumentTextResult(
        isSuccess: false,
        message: 'تعذر قراءة ملف النص من مساحة الجهاز.',
      );
    } on FormatException {
      return const LocalDocumentTextResult(
        isSuccess: false,
        message: 'ترميز ملف النص غير مدعوم. احفظه بترميز UTF-8 ثم أعد المحاولة.',
      );
    }
  }

  Future<LocalDocumentTextResult> _extractPdfText(String path) async {
    try {
      final text = (await ReadPdfText.getPDFtext(path)).trim();
      if (text.isEmpty) {
        return const LocalDocumentTextResult(
          isSuccess: false,
          message: 'لم يعثر PDF على طبقة نص. قد يكون ممسوحاً ضوئياً أو محمياً؛ يحتاج هذا النوع إلى OCR لكل صفحة.',
        );
      }
      return LocalDocumentTextResult(
        isSuccess: true,
        text: text,
        message: 'تم استخراج نص PDF محلياً. جارٍ اكتشاف لغته وترجمته إلى لغة جهازك…',
      );
    } catch (_) {
      return const LocalDocumentTextResult(
        isSuccess: false,
        message: 'تعذر استخراج نص PDF. جرّب ملف PDF نصياً غير محمي أو ملف TXT.',
      );
    }
  }
}
