import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// واجهة إذن الترجمة المباشرة. لا تُفعّل قراءة التطبيقات إلا بعد موافقة
/// المستخدم من إعدادات Android واختيار حزم التطبيقات المسموح بها.
class DirectTranslationAccessibilityService extends ChangeNotifier {
  static const _channel = MethodChannel('mirror_scorpion/direct_translation');

  bool _enabled = false;
  Set<String> _allowedPackages = <String>{};

  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isEnabled => _enabled;
  Set<String> get allowedPackages => Set.unmodifiable(_allowedPackages);

  Future<void> refresh() async {
    if (!isSupported) return;
    try {
      _enabled = await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
      final values = await _channel.invokeMethod<List<dynamic>>('getAllowedPackages');
      _allowedPackages = values?.whereType<String>().toSet() ?? <String>{};
      notifyListeners();
    } on PlatformException {
      _enabled = false;
      notifyListeners();
    }
  }

  Future<void> openAndroidSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<void> setAllowedPackages(Set<String> packages) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('setAllowedPackages', packages.toList(growable: false));
    _allowedPackages = {...packages};
    notifyListeners();
  }

  Future<void> setTargetLanguage(String code) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('setTargetLanguage', code);
  }

  Future<void> disableDirectCapture() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('disableDirectCapture');
  }
}
