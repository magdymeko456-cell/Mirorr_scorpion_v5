import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/local_ai/local_llm_model_catalog.dart';
import 'package:mirror_scorpion_v4/core/local_ai/local_model_pack.dart';

const sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, dynamic> entry({
  String status = 'available',
  String uri = 'https://models.example.test/story/manifest.json',
}) => {
      'id': 'story-ai-ar-small',
      'displayName': 'Story AI Arabic Small',
      'kind': 'storyAi',
      'languageCode': 'ar',
      'version': '1.0.0',
      'status': status,
      'manifestUri': uri,
      'manifestSha256': sha,
      'totalBytes': 400000000,
      'sourceName': 'Mirror Scorpion model catalog',
      'license': 'User-visible license required',
    };

void main() {
  test('parses an approved HTTPS generative model entry', () {
    final catalog = LocalLlmModelCatalog.fromJson({
      'catalogVersion': 1,
      'models': [entry()],
    });
    final model = catalog.models.single;
    expect(model.kind, LocalModelKind.storyAi);
    expect(model.canDownload, isTrue);
    expect(model.manifestUri.scheme, 'https');
  });

  test('does not make a model downloadable before review', () {
    final model = LocalLlmModelCatalog.fromJson({
      'catalogVersion': 1,
      'models': [entry(status: 'requires_review')],
    }).models.single;
    expect(model.canDownload, isFalse);
  });

  test('rejects HTTP model manifests', () {
    expect(
      () => LocalLlmModelCatalog.fromJson({
        'catalogVersion': 1,
        'models': [entry(uri: 'http://models.example.test/manifest.json')],
      }),
      throwsFormatException,
    );
  });

  test('rejects a catalog entry with a non-generative model kind', () {
    expect(
      () => LocalLlmModelCatalog.fromJson({
        'catalogVersion': 1,
        'models': [
          {
            ...entry(),
            'kind': 'voiceTts',
          },
        ],
      }),
      returnsNormally,
    );
    final model = LocalLlmModelCatalog.fromJson({
      'catalogVersion': 1,
      'models': [
        {
          ...entry(),
          'kind': 'voiceTts',
        },
      ],
    }).models.single;
    expect(model.canDownload, isFalse);
  });
}
