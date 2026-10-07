import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../local_ai/local_model_manager.dart';

/// Runtime paths for a verified Piper/VITS voice pack.
class LocalTtsPackConfig {
  const LocalTtsPackConfig({
    required this.packId,
    required this.modelFile,
    required this.tokensFile,
    required this.dataDirectory,
    this.lexiconFile = '',
    this.speakerId = 0,
  });

  final String packId;
  final String modelFile;
  final String tokensFile;
  final String dataDirectory;
  final String lexiconFile;
  final int speakerId;
}

enum LocalTtsState { idle, preparing, speaking, unavailable, failed }

class LocalTtsService extends ChangeNotifier {
  LocalTtsService({LocalModelManager? modelManager})
      : _modelManager = modelManager ?? const LocalModelManager();

  final LocalModelManager _modelManager;
  final AudioPlayer _player = AudioPlayer();
  sherpa.OfflineTts? _engine;
  LocalTtsPackConfig? _pack;
  LocalTtsState _state = LocalTtsState.idle;
  String? _message;
  bool _bindingsInitialized = false;

  LocalTtsState get state => _state;
  String? get message => _message;
  bool get isReady => _engine != null && _state != LocalTtsState.failed;
  bool get isSpeaking => _state == LocalTtsState.speaking;
  String? get loadedPackId => _pack?.packId;

  Future<bool> initialize(LocalTtsPackConfig pack) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return _fail('المحرك الصوتي المحلي متاح حالياً على Android وiOS فقط.');
    }
    _setState(LocalTtsState.preparing, null);
    try {
      final status = await _modelManager.inspect(pack.packId);
      if (!status.isReady) {
        return _fail(
          'حزمة الصوت المحلية غير جاهزة: ${status.message ?? status.state.name}.',
        );
      }
      final directory = status.directory.path;
      final model = File('$directory/${pack.modelFile}');
      final tokens = File('$directory/${pack.tokensFile}');
      final data = Directory('$directory/${pack.dataDirectory}');
      if (!await model.exists() || !await tokens.exists() || !await data.exists()) {
        return _fail('ملفات تشغيل حزمة الصوت المحلية غير مكتملة.');
      }
      if (!_bindingsInitialized) {
        sherpa.initBindings();
        _bindingsInitialized = true;
      }
      _engine?.free();
      _engine = sherpa.OfflineTts(
        sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: model.path,
              tokens: tokens.path,
              dataDir: data.path,
              lexicon: pack.lexiconFile.isEmpty
                  ? ''
                  : '$directory/${pack.lexiconFile}',
            ),
            numThreads: 2,
            debug: false,
            provider: 'cpu',
          ),
        ),
      );
      _pack = pack;
      _setState(LocalTtsState.idle, 'تم تجهيز محرك الصوت المحلي دون اتصال.');
      return true;
    } catch (_) {
      _engine?.free();
      _engine = null;
      return _fail('تعذر تشغيل محرك الصوت المحلي. تحقق من توافق الحزمة.');
    }
  }

  Future<bool> speak({required String text, double speed = 1.0}) async {
    final content = text.trim();
    final engine = _engine;
    final pack = _pack;
    if (content.isEmpty) return _fail('لا يوجد نص لقراءته محلياً.');
    if (engine == null || pack == null) {
      return _fail('نزّل حزمة الصوت المحلية المطلوبة أولاً.');
    }
    _setState(LocalTtsState.preparing, null);
    try {
      await _player.stop();
      final audio = engine.generate(
        text: content,
        sid: pack.speakerId,
        speed: speed.clamp(0.5, 2.0).toDouble(),
      );
      if (audio.samples.isEmpty || audio.sampleRate <= 0) {
        return _fail('لم ينتج محرك الصوت المحلي ملفاً صالحاً.');
      }
      final temporary = await getTemporaryDirectory();
      final output = File(
        '${temporary.path}/mirror_scorpion/local_tts_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      await output.parent.create(recursive: true);
      if (!sherpa.writeWave(
        filename: output.path,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      )) {
        return _fail('تعذر حفظ الصوت المحلي المؤقت.');
      }
      _setState(LocalTtsState.speaking, null);
      await _player.play(DeviceFileSource(output.path));
      _setState(LocalTtsState.idle, null);
      try {
        await output.delete();
      } catch (_) {}
      return true;
    } catch (_) {
      return _fail('تعذر تشغيل النطق المحلي.');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _setState(LocalTtsState.idle, null);
  }

  @override
  void dispose() {
    _engine?.free();
    _player.dispose();
    super.dispose();
  }

  bool _fail(String message) {
    _setState(LocalTtsState.unavailable, message);
    return false;
  }

  void _setState(LocalTtsState state, String? message) {
    _state = state;
    _message = message;
    notifyListeners();
  }
}
