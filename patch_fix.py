import os

file_path = 'lib/features/feature_hub_screen.dart'
if not os.path.exists(file_path):
    print("الملف غير موجود!")
    exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  Future<void> _swapDialogueSpeaker() async {"
end_marker = "  void _queueTranslation("

start_idx = content.find(start_marker)
end_idx = content.find(end_marker, start_idx)

if start_idx != -1 and end_idx != -1:
    new_code = """  Future<void> _swapDialogueSpeaker() async {
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
  }

  """
    
    updated_content = content[:start_idx] + new_code + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated_content)
    print("تم تحديث دوال الحوار بنجاح.")
else:
    print("خطأ في تحديد نطاق الدوال.")
