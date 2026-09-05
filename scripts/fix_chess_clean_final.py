import os

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # استبدال أي شكل قديم لكونستركتور Chess3dScreen بالصيغة السليمة الحديثة
    if "Chess3dScreen({Key? key})" in content:
        content = content.replace("Chess3dScreen({Key? key})", "Chess3dScreen({super.key})")
    elif "Chess3dScreen({super.key})" not in content:
        # البحث عن الكلاس وإصلاح السطر الأول تلقائياً
        content = content.replace("class Chess3dScreen extends StatelessWidget {", "class Chess3dScreen extends StatelessWidget {\n  const Chess3dScreen({super.key});")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تنظيف ملف chess_3d_screen.dart نهائياً.")
