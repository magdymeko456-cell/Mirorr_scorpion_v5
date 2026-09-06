#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/Mirorr_scorpion_v5"

# 1) إصلاح منطق الضغطتين: تبديل التسجيل عبر _dialogueCapture مباشرة
python3 - <<'PY'
import io
p = 'lib/features/feature_hub_screen.dart'
s = io.open(p, encoding='utf-8').read()

# فصل _startRecognition: يبدأ التسجيل فقط
old_start = """  Future<void> _startRecognition() async {
    final session = ++_sessionId;
    final capture = await _dialogueCapture.start();
    if (mounted) setState(() => _notice = capture.message);
    if (!capture.isSuccess) return;

    // مسار Whisper المحلي: ينتظر الضغط الثاني لإيقاف التسجيل ثم يفرّغ الملف.
    final stoppedPath = await _dialogueCapture.stop();"""
new_start = """  Future<void> _startRecognition() async {
    final session = ++_sessionId;
    final capture = await _dialogueCapture.start();
    if (mounted) setState(() => _notice = capture.message);
    if (!capture.isSuccess) return;
    // التسجيل جارٍ الآن؛ الضغطة التالية على المايك تستدعي _finishAndTranscribe.
  }

  Future<void> _finishAndTranscribe() async {
    final session = _sessionId;
    final stoppedPath = await _dialogueCapture.stop();"""
assert old_start in s, 'لم أجد بداية _startRecognition كما هو متوقع.'
s = s.replace(old_start, new_start, 1)

# تحويل _toggleMicrophone إلى تبديل التسجيل الجديد
old_toggle = """  Future<void> _toggleMicrophone() async {
    if (_isBusy || _speechService.isSpeaking) return;
    setState(() => _isBusy = true);
    try {
      if (_recognitionService.isListening) {
        await _finishRecognitionSession();
        if (mounted && _recognitionService.message != null) {
          setState(() => _notice = _recognitionService.message);
        }
        return;
      }
      await _speechService.stop();
      if (!mounted) return;
      if (_hasCompletedTranslation) {
        _source.clear();
        _translated.clear();
        _hasCompletedTranslation = false;
      }
      await _startRecognition();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }"""
new_toggle = """  Future<void> _toggleMicrophone() async {
    if (_isBusy || _speechService.isSpeaking) return;
    setState(() => _isBusy = true);
    try {
      if (_dialogueCapture.isRecording) {
        // الضغطة الثانية: إيقاف التسجيل والتفريغ بلغة المصدر.
        await _finishAndTranscribe();
        return;
      }
      await _speechService.stop();
      if (!mounted) return;
      if (_hasCompletedTranslation) {
        _source.clear();
        _translated.clear();
        _hasCompletedTranslation = false;
      }
      await _startRecognition();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }"""
assert old_toggle in s, 'لم أجد _toggleMicrophone كما هو متوقع.'
s = s.replace(old_toggle, new_toggle, 1)

io.open(p, 'w', encoding='utf-8').write(s)
print('تم إصلاح منطق الضغطتين.')
PY

# 2) إزالة ملفات النسخ الاحتياطي من المستودع
git rm --cached lib/core/speech/audio_transcriber_service.dart.pre_whisper lib/features/feature_hub_screen.dart.pre_whisper 2>/dev/null || true
rm -f lib/core/speech/audio_transcriber_service.dart.pre_whisper lib/features/feature_hub_screen.dart.pre_whisper

# 3) منع تكرار رفع النسخ الاحتياطية مستقبلاً
grep -q "pre_whisper" .gitignore || printf "\n*.pre_whisper\n*.bak\n" >> .gitignore

echo "=== الفرق النهائي ==="
git diff --stat
echo ""
echo "راجع ثم ارفع:"
echo "  git add -A && git commit -m 'fix(dialogue): two-press mic toggle + remove local backup files' && git push origin main"
