import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مؤثرات الشطرنج محلية بالكامل. لا يستخدم ميكروفوناً ولا يرسل بيانات.
class ChessSoundService {
  static const _mutedKey = 'chess_sound_muted';
  static const _root = 'audio/chess/';

  bool _muted = false;
  bool get isMuted => _muted;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _muted = preferences.getBool(_mutedKey) ?? false;
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_mutedKey, muted);
  }

  Future<void> playMove({required bool capture, required bool check, required bool checkmate}) async {
    if (checkmate) {
      await _play('chess_checkmate.wav', 0.72);
    } else if (check) {
      await _play('chess_check.wav', 0.58);
    } else if (capture) {
      await _play('chess_capture.wav', 0.72);
    } else {
      await _play('chess_move.wav', 0.52);
    }
  }

  Future<void> playUndo() => _play('chess_undo.wav', 0.42);

  Future<void> _play(String filename, double volume) async {
    if (_muted) return;
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('$_root$filename'), volume: volume);
      unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
    } catch (_) {
      await player.dispose();
    }
  }

  Future<void> dispose() async {}
}
