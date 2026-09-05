import os

path = "lib/features/audio/voice_selection_sheet.dart"
if os.path.exists(path):
    print(f"=== {path} ===")
    with open(path, "r", encoding="utf-8") as f:
        print(f.read()[:1500]) # طباعة أول جزء لفهم الهيكل
else:
    print("ملف خيارات الصوت غير موجود بهذا المسار، لنفحص البديل.")
    for root, dirs, files in os.walk("lib"):
        for file in files:
            if "voice" in file.lower() or "audio" in file.lower():
                print(f"وجدنا: {os.path.join(root, file)}")
