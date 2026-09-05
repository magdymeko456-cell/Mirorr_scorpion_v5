import os
import re

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()
    
    # استبدال تعريف المُنشئ بالطريقة القديمة بالطريقة الحديثة super.key
    code = re.sub(r'Chess3dScreen\s*\(\s*\{[^}]*Key\?\s*key[^}]*\}\s*\)\s*(?::\s*super\s*\(\s*key\s*:\s*key\s*\))?', 'Chess3dScreen({super.key})', code)
    code = re.sub(r'const\s+Chess3dScreen\s*\(\s*\{[^}]*Key\?\s*key[^}]*\}\s*\)\s*(?::\s*super\s*\(\s*key\s*:\s*key\s*\))?', 'const Chess3dScreen({super.key})', code)

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("✅ تم تحديث constructor في chess_3d_screen.dart بنجاح")
