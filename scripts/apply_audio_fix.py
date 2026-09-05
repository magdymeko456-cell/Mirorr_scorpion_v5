import os

path = "lib/features/feature_hub_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

target = """    try {
      selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AudioTranscriberService.supportedExtensions.toList()..sort(),
        withData: false,
      );"""

replacement = """    try {
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

if target in content:
    content = content.replace(target, replacement)
    
    # تنظيف أي كود تالف قديم
    bad_block = """    if (result != null && result.files.single.path != null) {
      final String path = result.files.single.path!;
      await _whisperService.transcribeAudio(path);
    }"""
    content = content.replace(bad_block, "")
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم ربط منتقي الملفات بـ Whisper بنجاح تام!")
else:
    print("⚠️ لم يتم العثور على النمط المستهدف بدقة.")
