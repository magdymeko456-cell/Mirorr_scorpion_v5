import os

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # حقن الكونستركتور القياسي الصحيح مباشرة بعد فتح الكلاس
    target = "class Chess3DScreen extends StatelessWidget {"
    replacement = "class Chess3DScreen extends StatelessWidget {\n  const Chess3DScreen({super.key});"
    
    if target in content and "const Chess3DScreen({super.key})" not in content:
        content = content.replace(target, replacement, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ تمت إضافة الكونستركتور القياسي بنجاح تام!")
    else:
        print("⚠️ الكلاس موجود بالفعل أو تم تعديله مسبقاً.")
