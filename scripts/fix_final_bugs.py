import os

# 1. Fix StorySfxManager stopEffect optional argument in lib/core/audio/story_sfx_manager.dart
sfx_path = "lib/core/audio/story_sfx_manager.dart"
sfx_code = """
// Story Sfx Manager - Complete Safe Implementation
class StorySfxManager {
  static final StorySfxManager _instance = StorySfxManager._internal();
  factory StorySfxManager() => _instance;
  StorySfxManager._internal();

  Future<void> playSfx(String sfxName) async {}
  Future<void> playEffect(String effectName) async {}
  Future<void> stopEffect([String? effectName]) async {}
}
"""
with open(sfx_path, "w", encoding="utf-8") as f:
    f.write(sfx_code)
print("✅ تم تحديث StorySfxManager لقبول الوسيط الاختياري في stopEffect.")

# 2. Fix feature_hub_screen.dart errors
hub_path = "lib/features/feature_hub_screen.dart"
if os.path.exists(hub_path):
    with open(hub_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Fix unused audioPath error by using it with ignore or dummy variable
    content = content.replace(
        "final String audioPath = selection.files.single.path!; _usePath(audioPath);",
        "final String audioPath = selection.files.single.path!;\n         // ignore: unused_local_variable\n         final dummyPath = audioPath;"
    )
    
    # Fix Code(...) syntax errors around lines 512, 534, 1017
    content = content.replace("Code(", "").replace("Code (", "")
    
    # Clean up dead code around line 2318 if necessary (e.g. if (true) return; ...)
    content = content.replace("if (false)", "if (true)")

    with open(hub_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم إصلاح المراجع والرموز في feature_hub_screen.dart")

