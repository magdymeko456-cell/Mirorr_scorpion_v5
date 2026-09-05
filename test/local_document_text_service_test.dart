import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/documents/local_document_text_service.dart';

void main() {
  test('classifies the supported local document kinds', () {
    expect(
      LocalDocumentTextService.kindForName('chapter.PDF'),
      LocalDocumentKind.pdf,
    );
    expect(
      LocalDocumentTextService.kindForName('notes.txt'),
      LocalDocumentKind.plainText,
    );
    expect(
      LocalDocumentTextService.kindForName('report.docx'),
      LocalDocumentKind.unsupported,
    );
  });

  test('keeps the device language as the only document translation target', () {
    expect(DocumentTranslationPolicy.targetForDevice('TR'), 'tr');
    expect(DocumentTranslationPolicy.targetForDevice(' ar '), 'ar');
  });

  test('reads a UTF-8 local text file without uploading it', () async {
    final directory = await Directory.systemTemp.createTemp('mirror-document-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/sample.txt');
    await file.writeAsString('Hello document');

    final result = await const LocalDocumentTextService().extract(
      path: file.path,
      fileName: 'sample.txt',
    );

    expect(result.isSuccess, isTrue);
    expect(result.text, 'Hello document');
  });
}
