import os
import re

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # التأكد من وجود الكونستركتور الصحيح الذي يتلقى {super.key} لجميع الويدجت العامة
    if "class Chess3dScreen" in content:
        # إزالة أي كونستركتور قديم أو خاطئ لـ Chess3dScreen
        content = re.sub(r'Chess3dScreen\s*\([^;]*\);', '', content)
        
        # حقن الكونستركتور الصحيح مباشرة تحت تعريف الكلاس
        content = re.sub(
            r'(class\s+Chess3dScreen\s+extends\s+StatelessWidget\s*\{)',
            r'\1\n  const Chess3dScreen({super.key});',
            content
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تصحيح و إضافة معلمة المفتاح {super.key} بنجاح تام.")
