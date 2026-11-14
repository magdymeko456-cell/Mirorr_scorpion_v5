import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/translation/translation_engine.dart';

void main() {
  test('current adapter identifies ML Kit explicitly', () {
    const engine = MlKitTranslationEngine();

    expect(engine.id, 'mlkit-on-device');
    expect(engine.displayName, contains('ML Kit'));
    expect(engine.isLocal, isTrue);
  });

  test('language preparation remains behind the engine contract', () async {
    const engine = MlKitTranslationEngine();
    final result = await engine.prepareLanguagePair(
      sourceLanguageCode: 'ar',
      targetLanguageCode: 'en',
    );

    expect(result.isSuccess, isFalse);
  });
}
