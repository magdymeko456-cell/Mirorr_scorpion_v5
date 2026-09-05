import os

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    # فحص سطر 5 وما حوله
    print("--- السطور الأولى قبل التعديل ---")
    for i in range(min(8, len(lines))):
        print(f"سطر {i+1}: {lines[i].rstrip()}")
    
    # بناء ملف نظيف بالكامل يعتمد على const Chess3dScreen({super.key}); مباشرة تحت اسم الكلاس
    clean_lines = []
    constructor_added = False
    
    for line in lines:
        # إذا كان السطر عبارة عن تعريف قديم للكونستركتور أو يحتوي على Key? key، نتخطاه
        if ("Chess3dScreen(" in line or "Key?" in line or "super(key:" in line) and "class" not in line:
            continue
        
        clean_lines.append(line)
        
        if "class Chess3dScreen" in line and not constructor_added:
            clean_lines.append("  const Chess3dScreen({super.key});\n")
            constructor_added = True

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(clean_lines)
    print("✅ تم إعادة كتابة الكونستركتور بالطريقة الحديثة بنجاح تامن.")

