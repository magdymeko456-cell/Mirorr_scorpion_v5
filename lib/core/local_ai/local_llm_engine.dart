import '../platform/device_capability_service.dart';
import 'local_model_pack.dart';

/// The first phase deliberately exposes a runtime-neutral contract. It keeps
/// UI features independent from a native LLM runtime until a tested Android
/// backend is added.
abstract interface class LocalLlmEngine {
  Future<LocalLlmResult> generate({
    required LocalLlmRequest request,
    void Function(String partialText)? onToken,
  });
}

class LocalLlmRequest {
  const LocalLlmRequest({
    required this.prompt,
    this.systemInstruction,
    this.maxTokens = 256,
    this.temperature = 0.7,
  });

  final String prompt;
  final String? systemInstruction;
  final int maxTokens;
  final double temperature;

  bool get isValid =>
      prompt.trim().isNotEmpty &&
      prompt.length <= 12000 &&
      maxTokens > 0 &&
      maxTokens <= 4096 &&
      temperature >= 0 &&
      temperature <= 2;
}

class LocalLlmResult {
  const LocalLlmResult.success(this.text)
      : isSuccess = true,
        message = null;
  const LocalLlmResult.failure(this.message)
      : isSuccess = false,
        text = null;

  final bool isSuccess;
  final String? text;
  final String? message;
}

class LocalLlmCompatibility {
  const LocalLlmCompatibility({
    required this.supported,
    required this.reason,
  });

  final bool supported;
  final String reason;
}

class LocalLlmCapabilityPolicy {
  const LocalLlmCapabilityPolicy._();

  static const int defaultMinimumRamBytes = 4 * 1000 * 1000 * 1000;
  static const int defaultMinimumFreeStorageBytes = 512 * 1024 * 1024;

  static LocalLlmCompatibility evaluate({
    required DeviceCapabilities device,
    required LocalModelPackManifest manifest,
  }) {
    if (manifest.kind != LocalModelKind.storyAi) {
      return const LocalLlmCompatibility(
        supported: false,
        reason: 'The selected pack is not a generative language model.',
      );
    }
    if (device.totalRamBytes <= 0 || device.availableStorageBytes <= 0) {
      return const LocalLlmCompatibility(
        supported: false,
        reason: 'Device capabilities are unavailable.',
      );
    }
    final minimumRam = manifest.minimumRamBytes == 0
        ? defaultMinimumRamBytes
        : manifest.minimumRamBytes;
    final minimumStorage = manifest.minimumFreeStorageBytes == 0
        ? defaultMinimumFreeStorageBytes
        : manifest.minimumFreeStorageBytes;
    if (device.totalRamBytes < minimumRam) {
      return LocalLlmCompatibility(
        supported: false,
        reason: 'This model requires at least $minimumRam bytes of RAM.',
      );
    }
    if (device.availableStorageBytes < minimumStorage) {
      return LocalLlmCompatibility(
        supported: false,
        reason: 'This model requires at least $minimumStorage bytes of free storage.',
      );
    }
    if (manifest.supportedAbis.isNotEmpty &&
        !manifest.supportedAbis.any(device.supportedAbis.contains)) {
      return const LocalLlmCompatibility(
        supported: false,
        reason: 'This model does not support the device ABI.',
      );
    }
    return const LocalLlmCompatibility(
      supported: true,
      reason: 'The device meets the model requirements.',
    );
  }
}

/// Safe placeholder until a native runtime is selected and tested. It makes
/// the product honest: no feature can silently fall back to a cloud service.
class UnavailableLocalLlmEngine implements LocalLlmEngine {
  const UnavailableLocalLlmEngine();

  @override
  Future<LocalLlmResult> generate({
    required LocalLlmRequest request,
    void Function(String partialText)? onToken,
  }) async {
    if (!request.isValid) {
      return const LocalLlmResult.failure('The local generation request is invalid.');
    }
    return const LocalLlmResult.failure(
      'No verified local generative model runtime is installed.',
    );
  }
}
