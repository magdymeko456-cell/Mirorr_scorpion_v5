import os
import re

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # البحث عن السطور الخاصة بتعريف الكلاس والكونستركتور واستبدالها بالصيغة الحديثة المباشرة
    # سنقوم بالبحث عن أي شكل لكونستركتور Chess3dScreen واستبداله بـ const Chess3dScreen({super.key});
    pattern = r'Chess3dScreen\s*\(\s*\{[^}]*\}\s*\)\s*(?::\s*super\s*\([^)]*\))?'
    
    new_content, count = re.subn(pattern, 'const Chess3dScreen({super.key})', content)
    if count == 0:
        # إذا لم يطابق النمط، نبحث عن الشكل التقليدي
        pattern_alt = r'Chess3dScreen\s*\([^)]*\)\s*(?::\s*super\s*\([^)]*\))?'
        new_content, count = re.subn(pattern_alt, 'const Chess3dScreen({super.key})', content)

    with open(path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print(f"✅ تم تعديل كونستركتور Chess3dScreen بنجاح (عدد التعديلات: {count})")
