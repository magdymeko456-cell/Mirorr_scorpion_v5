import os
path = "lib/features/audio/voice_selection_sheet.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        print(f.read())
