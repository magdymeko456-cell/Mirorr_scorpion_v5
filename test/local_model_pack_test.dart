import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/local_ai/local_model_pack.dart';

void main() {
  test('parses a verified local TTS pack manifest', () {
    final manifest = LocalModelPackManifest.fromJson({
      'id': 'voice-ar-calm',
      'kind': 'voiceTts',
      'languageCode': 'ar',
      'version': '1.0.0',
      'engine': 'sherpa-onnx-piper',
      'displayName': 'Arabic calm voice',
      'files': [
        {
          'path': 'model.onnx',
          'sha256': 'a' * 64,
          'bytes': 100,
        },
      ],
    });

    expect(manifest.kind, LocalModelKind.voiceTts);
    expect(manifest.languageCode, 'ar');
    expect(manifest.files.single.relativePath, 'model.onnx');
  });

  test('rejects unsafe or incomplete model file entries', () {
    expect(
      () => LocalModelPackManifest.fromJson({
        'id': 'voice-ar-calm',
        'kind': 'voiceTts',
        'languageCode': 'ar',
        'version': '1.0.0',
        'engine': 'sherpa-onnx-piper',
        'files': [
          {
            'path': '../model.onnx',
            'sha256': 'a' * 64,
            'bytes': 100,
          },
        ],
      }),
      throwsFormatException,
    );
  });
}
