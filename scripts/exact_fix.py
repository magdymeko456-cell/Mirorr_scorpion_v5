python3 -c '
file_path = "lib/features/feature_hub_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

target_snippet = """  Future<void> _pickAudioFileForLocalTranslation() async {
    if (_isInstallingAudioModel || _isTranscribingAudio) return;
    FilePickerResult? selection;
    try {
      selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioTranscriberService.supportedExtensions.toList()..sort(),
        withData: false,
      );"""

replacement_snippet = """  Future<void> _pickAudioFileForLocalTranslation() async {
    if (_isInstallingAudioModel || _isTranscribingAudio) return;
    FilePickerResult? selection;
    try {
      selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioTranscriberService.supportedExtensions.toList()..sort(),
        withData: false,
      );

      if (selection != null && selection.files.single.path != null) {
        final String audioPath = selection.files.single.path!;
        setState(() {
          _isTranscribingAudio = true;
          _notice = "جارٍ تفريغ الملف الصوتي بواسطة Whisper…";
        });
        
        final transcript = await _whisperService.transcribeAudio(audioPath);
        
        if (mounted) {
          setState(() {
            _input.text = transcript;
            _isTranscribingAudio = false;
            _notice = null;
          });
          _queueTranslation(transcript, sourceLanguageCode: sourceLanguage);
        }
      }"""

if target_snippet in content:
    content = content.replace(target_snippet, replacement_snippet)
    # تنظيف أي أسطر قديمة خاطئة إن وجدت
    content = content.replace("""    if (result != null && result.files.single.path != null) {
      final String path = result.files.single.path!;
      await _whisperService.transcribeAudio(path);
    }""", "")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تصحيح وربط دالة _pickAudioFileForLocalTranslation مع Whisper بنجاح تام!")
else:
    print("⚠️ لم يتم مطابقة النمط، جاري الفحص اليدوي.")
'
