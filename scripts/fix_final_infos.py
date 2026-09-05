import os
import re

print("🛠️ بدء التعديل النهائي لتحويل معلمات الشفافية وتوحيد معاملات super...")

# 1. Fix chess_3d_screen.dart
chess_path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(chess_path):
    with open(chess_path, "r", encoding="utf-8") as f:
        code = f.read()
    
    # Super parameters
    code = re.sub(r'Chess3dScreen\s*\(\s*\{\s*Key\?\s*key\s*\}\s*\)\s*:\s*super\s*\(\s*key\s*:\s*key\s*\)', 'const Chess3dScreen({super.key})', code)
    code = code.replace('Chess3dScreen({Key? key})', 'Chess3dScreen({super.key})')
    
    # withOpacity -> withValues(alpha: ...)
    code = re.sub(r'\.withOpacity\s*\(\s*([^)]+)\s*\)', r'.withValues(alpha: \1)', code)

    with open(chess_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("✅ تم تحديث chess_3d_screen.dart")

# 2. Fix voice_picker_widget.dart
voice_path = "lib/presentation/widgets/voice_picker_widget.dart"
if os.path.exists(voice_path):
    with open(voice_path, "r", encoding="utf-8") as f:
        code = f.read()
    
    # Super parameters
    code = re.sub(r'VoicePickerWidget\s*\(\s*\{\s*Key\?\s*key\s*\,?[^}]*\}\s*\)\s*:\s*super\s*\(\s*key\s*:\s*key\s*\)', 'VoicePickerWidget({super.key})', code)
    code = code.replace('VoicePickerWidget({Key? key})', 'VoicePickerWidget({super.key})')
    
    # withOpacity -> withValues(alpha: ...)
    code = re.sub(r'\.withOpacity\s*\(\s*([^)]+)\s*\)', r'.withValues(alpha: \1)', code)

    with open(voice_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("✅ تم تحديث voice_picker_widget.dart")

print("✨ تمت كافة الإصلاحات بنجاح تام!")
