import 'package:flutter/services.dart';

/// لقطة لموارد الهاتف قبل تشغيل تفريغ ملف صوت محلي. لا تجمع هذه الخدمة
/// معرفات الجهاز ولا ترسل المورد أو الملف إلى الشبكة.
class DeviceCapabilities {
  const DeviceCapabilities({
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.availableStorageBytes,
    required this.supportedAbis,
  });

  final int totalRamBytes;
  final int availableRamBytes;
  final int availableStorageBytes;
  final List<String> supportedAbis;

  factory DeviceCapabilities.fromPlatformMap(Map<Object?, Object?> values) {
    int valueFor(String key) => (values[key] as num?)?.toInt() ?? 0;
    final rawAbis = values['supportedAbis'];
    return DeviceCapabilities(
      totalRamBytes: valueFor('totalRamBytes'),
      availableRamBytes: valueFor('availableRamBytes'),
      availableStorageBytes: valueFor('availableStorageBytes'),
      supportedAbis: rawAbis is List
          ? rawAbis.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}

enum LocalAudioCompatibility {
  supported,
  insufficientMemory,
  insufficientStorage,
  unavailable,
}

class LocalAudioCompatibilityPolicy {
  const LocalAudioCompatibilityPolicy._();

  /// تعلن الشركات الذاكرة عادة بوحدة GB العشرية؛ لهذا نستخدم 4,000,000,000
  /// بايت حتى لا يرفض Android هاتفاً بسعة 4 GB بسبب اختلاف GB عن GiB.
  static const int minimumRamBytes = 4 * 1000 * 1000 * 1000;
  static const int minimumFreeStorageBytes = 512 * 1024 * 1024;

  static LocalAudioCompatibility evaluate(DeviceCapabilities device) {
    if (device.totalRamBytes <= 0 || device.availableStorageBytes <= 0) {
      return LocalAudioCompatibility.unavailable;
    }
    if (device.totalRamBytes < minimumRamBytes) {
      return LocalAudioCompatibility.insufficientMemory;
    }
    if (device.availableStorageBytes < minimumFreeStorageBytes) {
      return LocalAudioCompatibility.insufficientStorage;
    }
    return LocalAudioCompatibility.supported;
  }

  static String messageFor(LocalAudioCompatibility result) => switch (result) {
        LocalAudioCompatibility.supported =>
          'الهاتف مناسب لتفريغ الملف محلياً ابتداءً من 4 GB RAM. تتأثر السرعة أيضاً '
              'بالمعالج وطول التسجيل والمساحة الحرة؛ الأجهزة ذات الذاكرة الأعلى أنسب للملفات الطويلة.',
        LocalAudioCompatibility.insufficientMemory =>
          'تفريغ الملفات الصوتية محلياً يتطلب في هذه النسخة هاتفاً بذاكرة RAM قدرها '
              '4 GB أو أكثر. ستبقى بقية أدوات التطبيق متاحة.',
        LocalAudioCompatibility.insufficientStorage =>
          'المساحة الحرة غير كافية لتفريغ الملف محلياً. حرّر 512 MB على الأقل ثم أعد المحاولة.',
        LocalAudioCompatibility.unavailable =>
          'تعذر قراءة ذاكرة الهاتف أو مساحته، لذلك لن يبدأ تفريغ الملف محلياً.',
      };
}

class DeviceCapabilityService {
  DeviceCapabilityService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'mirror_scorpion/device_capabilities';
  final MethodChannel _channel;

  Future<DeviceCapabilities?> inspect() async {
    try {
      final values = await _channel.invokeMapMethod<Object?, Object?>('inspect');
      return values == null ? null : DeviceCapabilities.fromPlatformMap(values);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
