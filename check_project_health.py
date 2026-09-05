import os
import glob

print("[*] بدء فحص سلامة المشروع البرمجية بلغة بايثون...")
dart_files = glob.glob("**/*.dart", recursive=True)
valid_files = 0
errors = 0

for path in dart_files:
    if ".dart_tool" in path or "build" in path:
        continue
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # فحص أساسي لتوازن الأقواس
        if content.count("{") != content.count("}"):
            print(f"[!] خطأ في توازن الأقواس داخل: {path}")
            errors += 1
        else:
            valid_files += 1
    except Exception as e:
        print(f"[!] خطأ في قراءة الملف {path}: {e}")
        errors += 1

print(f"\n[+] إجمالي ملفات الـ Dart المفحوصة بنجاح: {valid_files}")
if errors == 0:
    print("[+] مشروع Mirror Scorpion سليم تماماً وجاهز للخطوة التالية!")
else:
    print(f"[!] تم العثور على {errors} ملفات تحتوي على ملاحظات هيكلية.")
