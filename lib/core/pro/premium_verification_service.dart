import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches only a result obtained from the server. Flutter never issues a
/// license or embeds an RSA private key or activation salt.
class PremiumVerificationService extends ChangeNotifier {
  static final PremiumVerificationService _instance =
      PremiumVerificationService._internal();

  factory PremiumVerificationService() => _instance;

  PremiumVerificationService._internal();

  static const _deviceIdKey = 'mirror_scorpion_pro_installation_id';
  late SharedPreferences _prefs;
  bool _isPremium = false;
  String _deviceId = '';
  String? _statusMessage;

  bool get isPremium => _isPremium;
  String get installationId => _deviceId;
  String? get statusMessage => _statusMessage;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceId = _prefs.getString(_deviceIdKey) ?? _createInstallationId();
    await _prefs.setString(_deviceIdKey, _deviceId);
    _isPremium = false;
  }

  String _createInstallationId() {
    final random = Random.secure();
    final randomPart = List.generate(10, (_) => random.nextInt(36).toRadixString(36))
        .join()
        .toUpperCase();
    return 'MS4-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}-$randomPart';
  }

  Future<void> applyServerVerification({
    required bool valid,
    String? message,
  }) async {
    _isPremium = valid;
    _statusMessage = message;
    notifyListeners();
  }
}
