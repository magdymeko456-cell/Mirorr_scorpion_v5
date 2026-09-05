import os

keywords = ["Chess3DScreen", "VoicePickerWidget", "audioplayers", "speech_to_text"]
print("--- فحص تتبع الروابط والمكونات في المشروع ---")
for root, dirs, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                for kw in keywords:
                    if kw in content:
                        print(f"🎯 تم العثور على '{kw}' داخل: {path}")
