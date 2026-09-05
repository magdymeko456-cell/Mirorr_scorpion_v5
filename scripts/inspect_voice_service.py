import os

path = "lib/core/services/voice_selection_service.dart"
if os.path.exists(path):
    print(f"=== {path} ===")
    with open(path, "r", encoding="utf-8") as f:
        print(f.read())
else:
    print("❌ ملف خدمة الأصوات غير موجود.")
