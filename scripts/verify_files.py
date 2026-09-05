import os

files_to_check = [
    "lib/core/voices/voice_manager.dart",
    "lib/core/audio/story_sfx_manager.dart"
]

for path in files_to_check:
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        open_braces = content.count("{")
        close_braces = content.count("}")
        is_balanced = open_braces == close_braces
        print(f"📄 الملف: {path}")
        print(f"   - الحجم: {len(content)} حرف")
        print(f"   - توازن الأقواس: {open_braces} مفتوح مقابل {close_braces} مغلق -> " + ("متوازن ✅" if is_balanced else "غير متوازن ❌"))
    else:
        print(f"❌ الملف غير موجود: {path}")
