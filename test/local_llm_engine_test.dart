import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/local_ai/local_llm_engine.dart';
import 'package:mirror_scorpion_v4/core/local_ai/local_model_pack.dart';
import 'package:mirror_scorpion_v4/core/platform/device_capability_service.dart';

LocalModelPackManifest storyManifest({
  int ram = 4000000000,
  int storage = 512 * 1024 * 1024,
  List<String> abis = const <String>['arm64-v8a'],
}) {
  return LocalModelPackManifest(
    id: 'story-ai-ar-small',
    kind: LocalModelKind.storyAi,
    languageCode: 'ar',
    version: '1.0.0',
    engine: 'local-llm-runtime',
    minimumRamBytes: ram,
    minimumFreeStorageBytes: storage,
    supportedAbis: abis,
    entryPoint: 'model.gguf',
    contextTokens: 2048,
    files: const <LocalModelFile>[],
  );
}

DeviceCapabilities device({
  int ram = 6000000000,
  int storage = 2 * 1024 * 1024 * 1024,
  List<String> abis = const <String>['arm64-v8a'],
}) {
  return DeviceCapabilities(
    totalRamBytes: ram,
    availableRamBytes: ram ~/ 2,
    availableStorageBytes: storage,
    supportedAbis: abis,
  );
}

void main() {
  test('accepts a compatible local story model', () {
    final result = LocalLlmCapabilityPolicy.evaluate(
      device: device(),
      manifest: storyManifest(),
    );
    expect(result.supported, isTrue);
  });

  test('rejects a model when RAM is insufficient', () {
    final result = LocalLlmCapabilityPolicy.evaluate(
      device: device(ram: 4000000000),
      manifest: storyManifest(ram: 6000000000),
    );
    expect(result.supported, isFalse);
    expect(result.reason, contains('RAM'));
  });

  test('rejects a model for an unsupported ABI', () {
    final result = LocalLlmCapabilityPolicy.evaluate(
      device: device(abis: const <String>['armeabi-v7a']),
      manifest: storyManifest(),
    );
    expect(result.supported, isFalse);
    expect(result.reason, contains('ABI'));
  });

  test('does not treat a voice pack as a generative model', () {
    final result = LocalLlmCapabilityPolicy.evaluate(
      device: device(),
      manifest: LocalModelPackManifest(
        id: 'voice-ar-calm',
        kind: LocalModelKind.voiceTts,
        languageCode: 'ar',
        version: '1.0.0',
        engine: 'sherpa-onnx-piper',
        files: const <LocalModelFile>[],
      ),
    );
    expect(result.supported, isFalse);
  });

  test('placeholder runtime never silently uses a cloud fallback', () async {
    const engine = UnavailableLocalLlmEngine();
    final result = await engine.generate(
      request: const LocalLlmRequest(prompt: 'اكتب قصة قصيرة'),
    );
    expect(result.isSuccess, isFalse);
    expect(result.message, contains('local generative model runtime'));
  });

  test('rejects invalid generation requests before runtime use', () async {
    const engine = UnavailableLocalLlmEngine();
    final result = await engine.generate(
      request: const LocalLlmRequest(prompt: '', maxTokens: 9000),
    );
    expect(result.isSuccess, isFalse);
    expect(result.message, contains('invalid'));
  });
}
