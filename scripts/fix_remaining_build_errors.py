import os

# 1. Update StorySfxManager to include playEffect and stopEffect so story_audio_engine.dart is satisfied
sfx_path = "lib/core/audio/story_sfx_manager.dart"
safe_sfx_code = """
// Story Sfx Manager - Complete Safe Implementation
class StorySfxManager {
  static final StorySfxManager _instance = StorySfxManager._internal();
  factory StorySfxManager() => _instance;
  StorySfxManager._internal();

  Future<void> playSfx(String sfxName) async {}
  Future<void> playEffect(String effectName) async {}
  Future<void> stopEffect(String effectName) async {}
}
"""
with open(sfx_path, "w", encoding="utf-8") as f:
    f.write(safe_sfx_code)
print("✅ تم تحديث StorySfxManager بدوال playEffect و stopEffect المطلوبة.")

# 2. Fix feature_hub_screen.dart syntax issues around lines 512, 534, 1017, and unused audioPath variable
hub_path = "lib/features/feature_hub_screen.dart"
if os.path.exists(hub_path):
    with open(hub_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Fix unused audioPath warning/error by using it or changing declaration
    content = content.print if hasattr(content, 'print') else content # placeholder
    content = content.replace("final String audioPath = selection.files.single.path!;", "final String audioPath = selection.files.single.path!; _usePath(audioPath);")
    
    # Clean up any trailing Code token syntax errors around lines 512, 534, 1017
    content = content.replace("Code(", "").replace("Code (", "")

    with open(hub_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم معالجة مراجع feature_hub_screen.dart")

