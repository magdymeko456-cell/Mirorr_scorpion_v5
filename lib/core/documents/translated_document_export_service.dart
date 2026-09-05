import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// ينشئ مخرج PDF فعلياً للنص المترجم، ثم يشاركه أو يرسله لخدمة الطباعة.
/// لا يعيد كتابة ملف المستخدم الأصلي ولا يرفعه إلى أي خادم.
class TranslatedDocumentExportService {
  const TranslatedDocumentExportService();

  static const _arabicFontAsset =
      'assets/fonts/NotoNaskhArabic-VariableFont_wght.ttf';

  Future<Uint8List> buildPdf({
    required String documentName,
    required String translatedText,
    required String targetLanguageLabel,
  }) async {
    final fontData = await rootBundle.load(_arabicFontAsset);
    final font = pw.Font.ttf(fontData);
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'Mirror Scorpion — ترجمة مستند',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: font, fontSize: 18),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'اللغة المستهدفة: $targetLanguageLabel',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
              pw.Divider(color: PdfColors.blueGrey300),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'أُنشئ محلياً بواسطة Mirror Scorpion',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              translatedText.trim(),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: font, fontSize: 14, lineSpacing: 5),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> sharePdf({
    required String documentName,
    required String translatedText,
    required String targetLanguageLabel,
  }) async {
    final bytes = await buildPdf(
      documentName: documentName,
      translatedText: translatedText,
      targetLanguageLabel: targetLanguageLabel,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: _fileNameFor(documentName),
    );
  }

  Future<void> printPdf({
    required String documentName,
    required String translatedText,
    required String targetLanguageLabel,
  }) async {
    final bytes = await buildPdf(
      documentName: documentName,
      translatedText: translatedText,
      targetLanguageLabel: targetLanguageLabel,
    );
    await Printing.layoutPdf(
      name: _fileNameFor(documentName),
      onLayout: (_) async => bytes,
    );
  }

  String _fileNameFor(String documentName) {
    final stem = documentName
        .replaceFirst(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${stem.isEmpty ? 'mirror_scorpion_translation' : stem}_translated.pdf';
  }
}
