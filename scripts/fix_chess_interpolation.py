import os

path = "lib/presentation/screens/games/chess_3d_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # إزالة الأقواس الزائدة في تعبير النص
    content = content.replace("'$row,$col'", "$row,$col") # احتياطاً
    content = content.replace("'${row},${col}'", "'$row,$col'")
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تصحيح الأقواس في سطر 74 بنجاح تامن.")
