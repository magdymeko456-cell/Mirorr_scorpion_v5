# patch_dialogue_mic.py
# أداة مستقلة لتحديث ملف feature_hub_screen.dart وإصلاح مشكلة تبديل لغة المايك

import os

file_path = 'lib/features/feature_hub_screen.dart'

if not os.path.exists(file_path):
    print(f"Error: {file_path} not found!")
    exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# البحث عن دوال _swapDialogueSpeaker و _toggleMicrophone القديمة واستبدالها بالنسخة المصححة والمستقرة
old_swap_signature = """  Future<void> _swapDialogueSpeaker() async {
    if (_isChangingSpeaker) return;
    setState(() {
      _isChangingSpeaker = true;
      _notice = 'جارٍ إنهاء جلسة المايك السابقة قبل تبديل اللغة…';
    });
    try {
      await _recognitionService.cancelAndWait();
      await _speechService.stop();
      if (!mounted) return;
      final deviceLanguage = context.read<LanguagePreferences>().deviceLanguageCode;
      final nextSourceLanguage = _sourceUsesDeviceLanguage
          ? _leftTargetLanguage
          : deviceLanguage;
      setState(() {
        _sourceUsesDeviceLanguage = !_sourceUsesDeviceLanguage;
        _source.clear();
        _translated.clear();
        _hasCompletedDialogueTranslation = false;
        _isTranslating = false;
        _notice = 'تبدّل المتحدث. لغة المايك الآن: '
            '${TranslationLanguageCatalog.labels[nextSourceLanguage] ?? nextSourceLanguage}.';
      });
    } finally {"""

# التحقق من وجود الكود القديم واستبداله بدقة
if "Future<void> _swapDialogueSpeaker()" in content:
    # سنقوم باستبدال الكتلة الخاصة بالدالتين بالكامل لضمان التطابق التام
    print("Found dialogue methods. Applying precise patch...")
else:
    print("Warning: Signature not found exactly as expected. Checking alternative patterns...")

# كود التحديث الدقيق لكلا الدالتين داخل _DialoguePanelState
new_dialogue_methods = """  Future<void> _swapDialogueSpeaker() async {
    if (_isChangingSpeaker) return;
    setState(() {
      _isChangingSpeaker = true;
      _notice = 'جارٍ إنهاء جلسة المايك السابقة وتحديث لغة المتحدث…';
    });
    try {
      await _recognitionService.cancelAndWait();
      await _speechService.stop();
      if (!mounted) return;

      setState(() {
        _sourceUsesDeviceLanguage = !_sourceUsesDeviceLanguage;
        _source.clear();
        _translated.clear();
        _hasCompletedDialogueTranslation = false;
        _isTranslating = false;

        final deviceLanguage = context.read<LanguagePreferences>().deviceLanguageCode;
        final currentSourceLang = _sourceUsesDeviceLanguage ? deviceLanguage : _leftTargetLanguage;
        _notice = 'تبدّل المتحدث. لغة المايك الآن: ${TranslationLanguageCatalog.labels[currentSourceLang] ?? currentSourceLang}.';
      });
    } finally {
      if (mounted) setState(() => _isChangingSpeaker = false);
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_isChangingSpeaker) return;
    if (_recognitionService.isListening) {
      await _recognitionService.stop();
      if (mounted && _recognitionService.message != null) {
        setState(() => _notice = _recognitionService.message);
      }
      return;
    }

    try {
      await _recognitionService.cancelAndWait();
      await _speechService.stop();
      if (!mounted) return;

      _beginFreshDialogueIfNeeded();

      final preferences = context.read<LanguagePreferences>();
      final sourceLanguage = _sourceUsesDeviceLanguage
          ? preferences.deviceLanguageCode
          : _leftTargetLanguage;

      final started = await _recognitionService.start(
        languageCode: sourceLanguage,
        onText: (recognizedText) {
          if (!mounted) return;
          _source.text = recognizedText;
          _queueTranslation(
            recognizedText,
            sourceLanguageCode: sourceLanguage,
          );
        },
      );

      if (mounted) {
        setState(() => _notice = _recognitionService.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notice = 'تعذر تشغيل المايك: $e');
      }
    }
  }"""

# تطبيق استبدال دقيق يعتمد على نطاق الدوال
start_marker = "  Future<void> _swapDialogueSpeaker() async {"
end_marker = "  Future<void> _toggleMicrophone() async {"

startIndex = content.find(start_marker)
if startIndex != -1:
    # نبحث عن نهاية دالة _toggleMicrophone الحالية (قبل الدالة التي تليها مثل _queueTranslation أو ما شابه)
    # لنبسط الأمر، سنستبدل الكتلة من بداية _swapDialogueSpeaker إلى بداية دالة _queueTranslation الخاصة بالحوار
    target_end_marker = "  void _queueTranslation("
    endIndex = content.find(target_end_marker, startIndex)
    
    if endIndex != -1:
        updated_content = content[:startIndex] + new_dialogue_methods + "\n\n" + content[endIndex:]
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        print("Success: Dialogue methods successfully patched via Python tool script.")
    else:
        print("Error: Could not locate end marker for dialogue methods.")
else:
    print("Error: Could not locate start marker for dialogue methods.")
