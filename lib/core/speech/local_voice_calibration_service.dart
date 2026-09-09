import 'package:shared_preferences/shared_preferences.dart';

/// نتيجة معايرة محلية: سرعة ونبرة مشتقتان من تسجيل المستخدم.
class LocalVoiceCalibration {
  const LocalVoiceCalibration({required this.speechRate, required this.pitch});
  final double speechRate;
  final double pitch;
}

/// تخزين المعايرة محلياً فقط (SharedPreferences). لا شيء يغادر الجهاز.
class LocalVoiceCalibrationStore {
  static const _rateKey = 'mirror_scorpion_myvoice_rate';
  static const _pitchKey = 'mirror_scorpion_myvoice_pitch';

  static Future<void> save({required double speechRate, required double pitch}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_rateKey, speechRate);
    await preferences.setDouble(_pitchKey, pitch);
  }

  static Future<LocalVoiceCalibration?> read() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rate = preferences.getDouble(_rateKey);
      final pitch = preferences.getDouble(_pitchKey);
      if (rate == null || pitch == null) return null;
      return LocalVoiceCalibration(speechRate: rate, pitch: pitch);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_rateKey);
    await preferences.remove(_pitchKey);
  }
}
