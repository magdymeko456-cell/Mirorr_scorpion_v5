import '../mlkit/on_device_translation_service.dart';

/// Contract used by feature screens so the native implementation can be
/// replaced by a verified local model without changing every card.
abstract interface class TranslationEngine {
  const TranslationEngine();

  String get id;
  String get displayName;
  bool get isLocal;

  Future<OnDeviceTranslationResult> translate({
    required String text,
    required String targetLanguageCode,
    String? sourceLanguageCode,
    OnDeviceTranslationProgressCallback? onProgress,
  });

  Future<OnDeviceModelPreparationResult> prepareLanguagePair({
    required String sourceLanguageCode,
    required String targetLanguageCode,
  });
}

/// Current production adapter. ML Kit is on-device after its language packs
/// are downloaded, but it is deliberately labelled as temporary so it is not
/// confused with the future generative local-model runtime.
class MlKitTranslationEngine implements TranslationEngine {
  const MlKitTranslationEngine({
    OnDeviceTranslationService service = const OnDeviceTranslationService(),
  }) : _service = service;

  final OnDeviceTranslationService _service;

  @override
  String get id => 'mlkit-on-device';

  @override
  String get displayName => 'ML Kit محلي (مؤقت)';

  @override
  bool get isLocal => true;

  @override
  Future<OnDeviceTranslationResult> translate({
    required String text,
    required String targetLanguageCode,
    String? sourceLanguageCode,
    OnDeviceTranslationProgressCallback? onProgress,
  }) => _service.translate(
        text: text,
        targetLanguageCode: targetLanguageCode,
        sourceLanguageCode: sourceLanguageCode,
        onProgress: onProgress,
      );

  @override
  Future<OnDeviceModelPreparationResult> prepareLanguagePair({
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) => _service.prepareLanguagePair(
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
      );
}
