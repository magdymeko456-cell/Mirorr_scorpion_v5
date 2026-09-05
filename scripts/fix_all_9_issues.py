import os
import re

print("🛠️ بدء إصلاح الشوائب الـ 9 لضمان نجاح flutter analyze بنسبة 100%...")

# 1. Fix feature_hub_screen.dart
hub_path = "lib/features/feature_hub_screen.dart"
if os.path.exists(hub_path):
    with open(hub_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Fix double quotes at line 298: _notice = "جارٍ تفريغ الملف الصوتي بواسطة Whisper…"; -> _notice = 'جارٍ تفريغ الملف الصوتي بواسطة Whisper…';
    content = content.replace('_notice = "جارٍ تفريغ الملف الصوتي بواسطة Whisper…";', "_notice = 'جارٍ تفريغ الملف الصوتي بواسطة Whisper…';")
    
    # Clean up dead code around line 2320
    content = content.replace("if (!true && mounted)", "if (false && mounted)")
    content = re.sub(r'//\s*ignore:\s*dead_code\s*\n\s*if\s*\([^)]+\)\s*[^;]+;', '', content)

    with open(hub_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تحديث feature_hub_screen.dart")

# 2. Fix chess_3d_screen.dart
chess_path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(chess_path):
    with open(chess_path, "r", encoding="utf-8") as f:
        chess_code = f.read()
    
    # Super parameter fix
    chess_code = re.sub(r'Chess3dScreen\s*\(\s*\{\s*Key\?\s*key\s*\}\s*\)\s*:\s*super\s*\(\s*key\s*:\s*key\s*\)', 'const Chess3dScreen({super.key})', chess_code)
    chess_code = chess_code.replace('Chess3dScreen({Key? key})', 'Chess3dScreen({super.key})')
    
    # withOpacity -> withValues
    chess_code = re.sub(r'\.withOpacity\s*\(\s*([^)]+)\s*\)', r'.withValues(opacity: \1)', chess_code)

    with open(chess_path, "w", encoding="utf-8") as f:
        f.write(chess_code)
    print("✅ تم تحديث chess_3d_screen.dart")

# 3. Fix voice_picker_widget.dart
voice_path = "lib/presentation/widgets/voice_picker_widget.dart"
if os.path.exists(voice_path):
    with open(voice_path, "r", encoding="utf-8") as f:
        voice_code = f.read()
    
    # Super parameter fix
    voice_code = re.sub(r'VoicePickerWidget\s*\(\s*\{\s*Key\?\s*key\s*\,?[^}]*\}\s*\)\s*:\s*super\s*\(\s*key\s*:\s*key\s*\)', 'VoicePickerWidget({super.key})', voice_code)
    voice_code = voice_code.replace('VoicePickerWidget({Key? key})', 'VoicePickerWidget({super.key})')
    
    # withOpacity -> withValues
    voice_code = re.sub(r'\.withOpacity\s*\(\s*([^)]+)\s*\)', r'.withValues(opacity: \1)', voice_code)

    with open(voice_path, "w", encoding="utf-8") as f:
        f.write(voice_code)
    print("✅ تم تحديث voice_picker_widget.dart")

print("✨ تم الانتهاء من كافة الإصلاحات بنجاح تام!")
