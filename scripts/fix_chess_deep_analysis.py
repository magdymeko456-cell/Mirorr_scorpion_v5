import os

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    print("--- محتوى أول 15 سطر من الملف ---")
    for i in range(min(15, len(lines))):
        print(f"سطر {i+1}: {lines[i].rstrip()}")
    
    # إعادة كتابة الملف مع تصحيح السطر الخاص بالكونستركتور
    new_lines = []
    fixed = False
    for line in lines:
        if "Chess3dScreen" in line and ("key" in line or "super" in line or "{" in line or ")" in line) and not fixed:
            # استبدال أي شكل قديم للكونستركتور بالصيغة القياسية الحديثة
            new_lines.append("  const Chess3dScreen({super.key});\n")
            fixed = True
            print("✨ تم تعديل السطر بنجاح إلى: const Chess3dScreen({super.key});")
        else:
            new_lines.append(line)
            
    # إذا لم يتم العثور بالطريقة السابقة، نبحث عن تعريف الكلاس ونحقن الكونستركتور تحته مباشرة
    if not fixed:
        final_lines = []
        for line in new_lines:
            final_lines.append(line)
            if "class Chess3dScreen" in line:
                final_lines.append("  const Chess3dScreen({super.key});\n")
                fixed = True
        new_lines = final_lines

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    print("✅ تم حفظ الملف بالصيغة السليمة.")
