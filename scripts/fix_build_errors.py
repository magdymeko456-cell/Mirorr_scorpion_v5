import os

# 1. Fix chess_3d_screen.dart (change onPress to onPressed)
chess_path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(chess_path):
    with open(chess_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("onPress: onPressed,", "onPressed: onPressed,")
    with open(chess_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تصحيح onPress إلى onPressed في chess_3d_screen.dart")

# 2. Fix voice_picker_widget.dart (remove unnecessary toList() in spread)
voice_path = "lib/presentation/widgets/voice_picker_widget.dart"
if os.path.exists(voice_path):
    with open(voice_path, "r", encoding="utf-8") as f:
        content = f.read()
    # Remove .toList() at the end of the map if present
    content = content.replace(".toList()", "")
    with open(voice_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم إزالة toList الزائدة في voice_picker_widget.dart")

# 3. Add audioplayers to pubspec.yaml if not present
pubspec_path = "pubspec.yaml"
if os.path.exists(pubspec_path):
    with open(pubspec_path, "r", encoding="utf-8") as f:
        pubspec = f.read()
    if "audioplayers:" not in pubspec:
        pubspec = pubspec.replace("dependencies:", "dependencies:\n  audioplayers: ^6.0.0")
        with open(pubspec_path, "w", encoding="utf-8") as f:
            f.write(pubspec)
        print("✅ تم إضافة حزمة audioplayers إلى pubspec.yaml")

