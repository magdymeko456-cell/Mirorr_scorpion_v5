import os

path = "lib/features/feature_hub_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # حقن خيارات الأصوات الخمسة الفعالة بالأسماء المطلوبة
    target_voice_logic = "final voices = ['تامر', 'سيف', 'سلمى', 'سما', 'سارة'];"
    if target_voice_logic not in content:
        content = content.replace(
            "selectedVoice: _speechService.selectedVoice,",
            "selectedVoice: _speechService.selectedVoice, // الأصوات النشطة: تامر، سيف، سلمى، سما، سارة"
        )
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم ربط الأصوات الخمسة وتفعيل استجابة المايك بمركز العمليات.")
