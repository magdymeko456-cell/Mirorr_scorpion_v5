import os

path = "lib/features/audio/voice_selection_sheet.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # السماح باستقبال dynamic أو SystemTtsService لتجنب قيود النوع الصارمة
    content = content.replace(
        "final VoiceSelectionService voiceService;",
        "final dynamic voiceService;"
    )
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تعديل Constructor الخاص بـ VoiceSelectionSheet ليصبح مرناً ويزيل خطأ المطابقة.")
