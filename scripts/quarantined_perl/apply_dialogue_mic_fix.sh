#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/mirror_scorpion_v4"
FILE="$ROOT/lib/features/feature_hub_screen.dart"
cd "$ROOT"

[[ -f "$FILE" ]] || { echo "الملف غير موجود: $FILE" >&2; exit 1; }

# يسمح بوجود ملفات تشخيص غير متتبعة، لكنه يمنع الكتابة فوق تعديلات كود محلية.
if [[ -n "$(git diff --name-only)" || -n "$(git diff --cached --name-only)" ]]; then
  echo "توجد تعديلات كود غير محفوظة. احفظها أو أزلها أولاً:" >&2
  git status --short >&2
  exit 1
fi

git switch main >/dev/null
git pull --rebase origin main

# الحالة الافتراضية: لغة الجهاز تملأ مصدر المايك الأيمن مرة واحدة فقط.
perl -0pi -e 's/  bool _sourceUsesDeviceLanguage = true;\n/  \/\/ لغة المصدر في الجهة اليمنى؛ لغة الجهاز مجرد قيمة ابتدائية.\n  String _rightSourceLanguage = '\''en'\'';\n/g' "$FILE"
perl -0pi -e 's/  \/\/\? لغة التقاط المايك: لغة الجهاز كافتراضي، أو اللغة المقابلة التي\n  \/\/\? اختارها المستخدم بعد تبديل مصدر الحوار\.\n  String get _dialogueMicLanguageCode \{\n    final deviceLanguage =\n        context\.read<LanguagePreferences>\(\)\.deviceLanguageCode;\n    return _sourceUsesDeviceLanguage \? deviceLanguage : _leftTargetLanguage;\n  \}/  \/\/ المايك يتبع دائماً لغة الجهة اليمنى، ولا يتبع لغة الجهاز بعد التهيئة.\n  String get _dialogueMicLanguageCode => _rightSourceLanguage;/g' "$FILE"
perl -0pi -e 's/    _leftTargetLanguage = preferences\.translationTargetLanguage;\n    _loadedLanguagePreferences = true;/    _leftTargetLanguage = preferences.translationTargetLanguage;\n    _rightSourceLanguage = preferences.deviceLanguageCode;\n    _loadedLanguagePreferences = true;/g' "$FILE"

# اختيار لغة الهدف اليسرى أو لغة المصدر اليمنى.
perl -0pi -e 's/  Future<void> _selectLeftTargetLanguage\(String code\) async \{.*?\n  \}\n\n  Future<void> _swapDialogueSpeaker/  Future<void> _selectLeftTargetLanguage(String code) async {\n    setState(() => _leftTargetLanguage = code);\n    await context.read<LanguagePreferences>().setTranslationTargetLanguage(code);\n    if (!mounted) return;\n    _queueTranslation(_source.text, sourceLanguageCode: _dialogueMicLanguageCode);\n  }\n\n  Future<void> _selectRightSourceLanguage(String code) async {\n    final wasListening = _recognitionService.isListening;\n    if (wasListening && !await _recognitionService.cancelAndWait()) return;\n    if (!mounted) return;\n    setState(() => _rightSourceLanguage = code);\n    if (wasListening) await _startDialogueMicrophone();\n  }\n\n  Future<void> _swapDialogueSpeaker/s' "$FILE"

# زر التبديل يبادل اليمين واليسار ويعيد تشغيل المايك إن كان يعمل.
perl -0pi -e 's/  Future<void> _swapDialogueSpeaker\(\) async \{.*?\n  \}\n\n  Future<void> _toggleMicrophone/  Future<void> _swapDialogueSpeaker() async {\n    if (_isChangingSpeaker) return;\n    final wasListening = _recognitionService.isListening;\n    setState(() {\n      _isChangingSpeaker = true;\n      _notice = '\''جارٍ تبديل مصدر المايك…'\'';\n    });\n    try {\n      if (wasListening && !await _recognitionService.cancelAndWait()) return;\n      await _speechService.stop();\n      if (!mounted) return;\n      final oldSource = _rightSourceLanguage;\n      setState(() {\n        _rightSourceLanguage = _leftTargetLanguage;\n        _leftTargetLanguage = oldSource;\n        _source.clear();\n        _translated.clear();\n        _hasCompletedDialogueTranslation = false;\n        _isTranslating = false;\n        _notice = '\''تبدّل المتحدث. لغة المايك الآن: '\''\n            '\''\${TranslationLanguageCatalog.labels[_rightSourceLanguage] ?? _rightSourceLanguage}.'\'';\n      });\n      await context.read<LanguagePreferences>().setTranslationTargetLanguage(_leftTargetLanguage);\n      if (wasListening) await _startDialogueMicrophone();\n    } finally {\n      if (mounted) setState(() => _isChangingSpeaker = false);\n    }\n  }\n\n  Future<void> _startDialogueMicrophone() async {\n    if (!mounted) return;\n    final sourceLanguage = _dialogueMicLanguageCode;\n    await _speechService.stop();\n    if (!mounted) return;\n    await _recognitionService.start(\n      languageCode: sourceLanguage,\n      onText: (recognizedText) {\n        if (!mounted) return;\n        _source.text = recognizedText;\n        _queueTranslation(recognizedText, sourceLanguageCode: sourceLanguage);\n      },\n    );\n    if (mounted && _recognitionService.message != null) {\n      setState(() => _notice = _recognitionService.message);\n    }\n  }\n\n  Future<void> _toggleMicrophone/s' "$FILE"

# تشغيل المايك يستخدم الدالة المشتركة.
perl -0pi -e 's/    if \(!mounted\) return;\n    final sourceLanguage = _dialogueMicLanguageCode;\n    await _speechService\.stop\(\);\n    if \(!mounted\) return;\n    _beginFreshDialogueIfNeeded\(\);\n    await _recognitionService\.start\(.*?\n    \}\);\n    if \(mounted && _recognitionService\.message != null\) \{\n      setState\(\(\) => _notice = _recognitionService\.message\);\n    \}/    if (!mounted) return;\n    _beginFreshDialogueIfNeeded();\n    await _startDialogueMicrophone();/s' "$FILE"

# الترجمة والنطق: الهدف يساراً، والمصدر يميناً.
perl -0pi -e 's/    final deviceLanguage = context\.read<LanguagePreferences>\(\)\.deviceLanguageCode;\n    final targetLanguage = _sourceUsesDeviceLanguage\n        \? _leftTargetLanguage\n        : deviceLanguage;/    final targetLanguage = _leftTargetLanguage;/g' "$FILE"
perl -0pi -e 's/sourceLanguageCode:\n          sourceLanguageCode \?\?\n              \(_sourceUsesDeviceLanguage\n                  \? deviceLanguage\n                  : _leftTargetLanguage\),/sourceLanguageCode: sourceLanguageCode ?? _dialogueMicLanguageCode,/g' "$FILE"
perl -0pi -e 's/    final currentDeviceLanguage = context\.read<LanguagePreferences>\(\)\.deviceLanguageCode;\n    final expectedTargetLanguage = _sourceUsesDeviceLanguage\n        \? _leftTargetLanguage\n        : currentDeviceLanguage;/    final expectedTargetLanguage = _leftTargetLanguage;/g' "$FILE"
perl -0pi -e 's/languageCode: _sourceUsesDeviceLanguage\n          \? _leftTargetLanguage\n          : context\.read<LanguagePreferences>\(\)\.deviceLanguageCode,/languageCode: _leftTargetLanguage,/g' "$FILE"

# واجهة واضحة: الهدف يساراً، والمصدر القابل للتغيير يميناً.
perl -0pi -e 's/label: _sourceUsesDeviceLanguage\n              \? '\''المحرر العلوي — المتحدث بلغة الجهاز'\''\n              : '\''المحرر العلوي — المتحدث باللغة المقابلة'\'',\n          hint: _sourceUsesDeviceLanguage\n              \? '\''اكتب أو تحدث بلغة جهازك…'\''\n              : '\''اكتب أو تحدث باللغة المقابلة…'\'',/label: '\''المحرر العلوي — مصدر المايك (الجهة اليمنى)'\'',\n          hint: '\''اكتب أو تحدث بلغة المصدر المحددة يميناً…'\'',/g' "$FILE"
perl -0pi -e 's/sourceLanguageCode: _sourceUsesDeviceLanguage\n                \? deviceLanguage\n                : _leftTargetLanguage,/sourceLanguageCode: _dialogueMicLanguageCode,/g' "$FILE"
perl -0pi -e 's/Expanded\(\n                    child: _DeviceSpeechLanguageLabel\(.*?\n                  Expanded\(\n                    child: _DialogueLanguageMenu\(\n                      value: _leftTargetLanguage,\n                      label: _sourceUsesDeviceLanguage.*?\n                    \),\n                  \),/Expanded(\n                    child: _DialogueLanguageMenu(\n                      value: _leftTargetLanguage,\n                      label: '\''لغة الترجمة (الجهة اليسرى)'\'',\n                      onChanged: _selectLeftTargetLanguage,\n                    ),\n                  ),\n                  IconButton(\n                    tooltip: '\''تبديل لغة الترجمة ومصدر المايك'\'',\n                    onPressed: _isChangingSpeaker ? null : _swapDialogueSpeaker,\n                    icon: const Icon(Icons.swap_horiz_rounded, color: RoyalColors.gold, size: 28),\n                  ),\n                  Expanded(\n                    child: _DialogueLanguageMenu(\n                      value: _rightSourceLanguage,\n                      label: '\''مصدر المايك (الجهة اليمنى)'\'',\n                      onChanged: _selectRightSourceLanguage,\n                    ),\n                  ),/s' "$FILE"

if grep -q '_sourceUsesDeviceLanguage' "$FILE"; then
  echo 'ما زالت مراجع قديمة للغة الجهاز موجودة؛ أوقف العملية للمراجعة.' >&2
  exit 1
fi

git diff --check
git add lib/features/feature_hub_screen.dart
if ! git diff --cached --quiet; then
  git commit -m 'fix(dialogue): use right-side language as microphone source'
fi
git push origin main
echo 'تم تطبيق إصلاح حوار المايك ودفعه إلى GitHub.'
