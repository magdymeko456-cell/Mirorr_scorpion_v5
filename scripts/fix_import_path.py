import os

path = "lib/features/feature_hub_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    content = content.replace("import '../audio/voice_selection_sheet.dart';", "import 'audio/voice_selection_sheet.dart';")
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تصحيح مسار استيراد ملف الأصوات بنجاح.")
