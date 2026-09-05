import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/mlkit/on_device_translation_service.dart';

void main() {
  test('translation failure diagnostics expose only the native error code', () {
    final detail = OnDeviceTranslationService.failureDetail(
      PlatformException(
        code: 'MODEL_DOWNLOAD_FAILED',
        message: '/data/user/0/private-model-path',
      ),
    );

    expect(detail, 'رمز ML Kit: MODEL_DOWNLOAD_FAILED.');
    expect(detail, isNot(contains('/data/user/0')));
  });

  test('does not try to download models outside a native platform', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final result = await const OnDeviceTranslationService().prepareLanguagePair(
      sourceLanguageCode: 'ar',
      targetLanguageCode: 'en',
    );

    expect(result.state, OnDeviceModelPreparationState.unsupportedPlatform);
    expect(result.isSuccess, isFalse);
  });
}
