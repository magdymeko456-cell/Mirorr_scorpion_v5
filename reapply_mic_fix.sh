#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/Mirorr_scorpion_v5"

# ===== 1) دورة حياة المسجّل: مسجّل جديد لكل جلسة =====
python3 - <<'PY'
import io
p = 'lib/core/speech/dialogue_voice_capture_service.dart'
s = io.open(p, encoding='utf-8').read()

old = """class DialogueVoiceCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _activePath;

  bool get isRecording => _activePath != null;"""
new = """class DialogueVoiceCaptureService {
  // مسجّل جديد لكل جلسة: يتجنب علل إعادة الاستخدام في record على بعض الأجهزة.
  AudioRecorder? _recorder;
  String? _activePath;

  AudioRecorder get _current => _recorder ??= AudioRecorder();

  bool get isRecording => _activePath != null;"""
assert old in s, 'A: لم أجد ترويسة الخدمة — ربما الإصلاح مطبق مسبقاً.'
s = s.replace(old, new, 1)
s = s.replace("      if (!await _recorder.hasPermission()) {",
              "      if (!await _current.hasPermission()) {", 1)
s = s.replace("      await _recorder.start(", "      await _current.start(", 1)

old_stop = """  Future<String?> stop() async {
    final path = _activePath;
    _activePath = null;
    if (path == null) return null;
    try {
      final stoppedPath = await _recorder.stop();
      return stoppedPath ?? (await File(path).exists() ? path : null);
    } catch (_) {
      return null;
    }
  }"""
new_stop = """  Future<String?> stop() async {
    final path = _activePath;
    _activePath = null;
    if (path == null) return null;
    final recorder = _recorder;
    _recorder = null; // مسجّل جديد للجلسة القادمة
    try {
      final stoppedPath = await recorder?.stop();
      try { await recorder?.dispose(); } catch (_) {}
      return stoppedPath ?? (await File(path).exists() ? path : null);
    } catch (_) {
      try { await recorder?.dispose(); } catch (_) {}
      return null;
    }
  }"""
assert old_stop in s, 'B: لم أجد stop.'
s = s.replace(old_stop, new_stop, 1)

old_dispose = """  Future<void> dispose() async {
    if (_activePath != null) {
      try { await _recorder.stop(); } catch (_) {}
      _activePath = null;
    }
    try { await _recorder.dispose(); } catch (_) {}
  }"""
new_dispose = """  Future<void> dispose() async {
    _activePath = null;
    try { await _recorder?.stop(); } catch (_) {}
    try { await _recorder?.dispose(); } catch (_) {}
    _recorder = null;
  }"""
assert old_dispose in s, 'C: لم أجد dispose.'
s = s.replace(old_dispose, new_dispose, 1)
io.open(p, 'w', encoding='utf-8').write(s)
print('1) دورة حياة المسجّل أُعيدت.')
PY

# ===== 2) فحص التسجيل من الخدمة الصحيحة =====
python3 - <<'PY'
import io
p = 'lib/features/feature_hub_screen.dart'
s = io.open(p, encoding='utf-8').read()
old = 'final wasListening = _recognitionService.isListening;'
n = s.count(old)
if n:
    s = s.replace(old, 'final wasListening = _dialogueCapture.isRecording;')
    io.open(p, 'w', encoding='utf-8').write(s)
print(f'2) صُحّح wasListening في {n} مواضع.')
PY

git diff --stat
echo "بعد المراجعة:"
echo "  git add lib/ && git commit -m 'fix(dialogue): per-session recorder lifecycle (reapplied)' && git push origin main"
