#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/Mirorr_scorpion_v5"

python3 - <<'PY'
import io
p = 'lib/features/feature_hub_screen.dart'
s = io.open(p, encoding='utf-8').read()

# 1) إضافة حقول Whisper داخل _DialoguePanelState
old_fields = """  final _translationService = const OnDeviceTranslationService();
  final _speechService = SystemTtsService(storageKey: 'dialoguepanelstate');
  Timer? _translationDebounce;"""
new_fields = """  final _translationService = const OnDeviceTranslationService();
  final _speechService = SystemTtsService(storageKey: 'dialoguepanelstate');
  final _dialogueCapture = DialogueVoiceCaptureService();
  final _transcriber = AudioTranscriberService();
  final _whisperInstaller = WhisperModelInstaller();
  File? _whisperModelFile;
  Timer? _translationDebounce;"""
assert old_fields in s, 'لم أجد حقول _DialoguePanelState كما هو متوقع.'
s = s.replace(old_fields, new_fields, 1)

# 2) استيراد المثبّت وdart:io إن لم يكنا موجودين
if "import 'dart:io';" not in s:
    s = "import 'dart:io';\n\n" + s
anchor = "import '../core/speech/audio_transcriber_service.dart';"
assert anchor in s, 'لم أجد استيراد audio_transcriber_service.'
if "whisper_model_installer" not in s:
    s = s.replace(anchor, anchor + "\nimport '../core/speech/whisper_model_installer.dart';", 1)

# 3) تهيئة النموذج في initState وتنظيف الموارد في dispose
old_init = """    _recognitionService.addListener(_refresh);
    _speechService.addListener(_refresh);
    _speechService.initialize();
    _loadPersistedDialogueLanguages();
  }"""
new_init = """    _recognitionService.addListener(_refresh);
    _speechService.addListener(_refresh);
    _speechService.initialize();
    _loadPersistedDialogueLanguages();
    _loadWhisperModel();
  }

  Future<void> _loadWhisperModel() async {
    try {
      final file = await _whisperInstaller
          .verifiedInstalledModel(WhisperModelDescriptor.baseMultilingual);
      if (!mounted || file == null) return;
      setState(() => _whisperModelFile = file);
    } catch (_) {
      // يبقى النموذج null وتظهر رسالة إرشادية عند استخدام المايك.
    }
  }"""
assert old_init in s, 'لم أجد initState كارت الحوار كما هو متوقع.'
s = s.replace(old_init, new_init, 1)

io.open(p, 'w', encoding='utf-8').write(s)
print('تم توصيل الحقول وinitState داخل _DialoguePanelState.')
PY

# 4) تنظيف الموارد في dispose كارت الحوار (إن وجد)
python3 - <<'PY'
import io, re
p = 'lib/features/feature_hub_screen.dart'
s = io.open(p, encoding='utf-8').read()
# ابحث عن dispose داخل _DialoguePanelState فقط
idx = s.find('class _DialoguePanelState')
seg_start = s.find('{', idx)
dispose_match = re.search(r'\n  @override\n  void dispose\(\) \{', s[idx:])
if dispose_match:
    abs_pos = idx + dispose_match.end()
    insertion = ("\n    _dialogueCapture.dispose();\n"
                 "    _whisperInstaller.dispose();\n"
                 "    _transcriber.._ = _transcriber; // no-op; AudioTranscriberService بلا dispose")
    s = s[:abs_pos] + insertion + s[abs_pos:]
    io.open(p, 'w', encoding='utf-8').write(s)
    print('تمت إضافة التنظيف إلى dispose كارت الحوار.')
else:
    print('تحذير: لم أجد dispose داخل _DialoguePanelState — راجع يدوياً.')
PY

echo "=== الفرق الحالي ==="
git diff --stat
echo ""
echo "=== خطوات التحقق التالية ==="
echo "1) راجع الفرق:  git diff | less"
echo "2) ارفع وشغّل بناء GitHub Actions (هو الباحث عن حقل language في الحزمة):"
echo "   git add -A && git commit -m 'feat(dialogue): local Whisper mic path with explicit source language' && git push origin main"
