import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/documents/translated_document_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ينشئ مخرج PDF مترجماً صالحاً من النص المحلي', () async {
    final bytes = await const TranslatedDocumentExportService().buildPdf(
      documentName: 'example.pdf',
      translatedText: 'هذه ترجمة اختبارية للمستند.',
      targetLanguageLabel: 'العربية',
    );

    expect(bytes.length, greaterThan(4));
    expect(bytes.sublist(0, 4), equals(<int>[37, 80, 68, 70]));
  });
}
