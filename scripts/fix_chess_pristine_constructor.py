import os
import re

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # تنظيف أي كونستركتور قديم أو متداخل بالكامل
    content = re.sub(r'Chess3dScreen\s*\([^)]*\)\s*(?::\s*super\s*\([^)]*\))?\s*;?', '', content)
    
    # حقن الكونستركتور القياسي الصحيح مباشرة بعد تعريف الكلاس
    pattern = r'(class\s+Chess3dScreen\s+extends\s+StatelessWidget\s*\{)'
    replacement = r'\1\n  const Chess3dScreen({super.key});'
    
    if re.search(pattern, content):
        content = re.sub(pattern, replacement, content, count=1)
    else:
        content = re.sub(r'(class\s+Chess3dScreen[^{]*\{)', r'\1\n  const Chess3dScreen({super.key});', content, count=1)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم إعادة هندسة وتركيب الكونستركتور النظيف في chess_3d_screen.dart")
