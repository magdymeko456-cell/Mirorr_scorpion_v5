import os
import re

def comprehensive_inspect_and_fix():
    print("🔍 بدء الفحص الشامل لملفات مشروع Mirror Scorpion v4...")
    
    dart_files = []
    for root, dirs, files in os.walk("lib"):
        for file in files:
            if file.endswith(".dart"):
                dart_files.append(os.path.join(root, file))
    
    issues_fixed = 0
    
    for filepath in dart_files:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        
        original_content = content
        
        # 1. إزالة الشوائب وتعبيرات Code الملتصقة بالنصوص أو المتغيرات
        content = re.sub(r"['\"]([a-z_-]+)['\"]Code\b", r"'\1'", content)
        content = content.replace("sourceLanguageCode: 'ar'Code", "sourceLanguageCode: 'ar'")
        content = content.replace("sourceLanguageCode: 'en'Code", "sourceLanguageCode: 'en'")
        
        # 2. فحص وتصحيح الأقواس المتعرجة العالقة أو التكرارات الخاطئة
        content = re.sub(r'\bCode\s*\(\s*\)', "''", content)
        
        # 3. التحقق من توازن الأقواس الرئيسية (للتنبيه أو التعديل)
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            print(f"تحذير ⚠️: عدم توازن الأقواس {{}} في الملف: {filepath} (مفتوح: {open_braces}, مغلق: {close_braces})")

        open_parens = content.count('(')
        close_parens = content.count(')')
        if open_parens != close_parens:
            print(f"تحذير ⚠️: عدم توازن الأقواس () في الملف: {filepath} (مفتوح: {open_parens}, مغلق: {close_parens})")

        if content != original_content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"✅ تم إصلاح وتنظيف الملف: {filepath}")
            issues_fixed += 1

    print(f"\n✨ اكتمل الفحص الشامل. تم فحص {len(dart_files)} ملف وتصحيح {issues_fixed} ملف بنجاح.")

if __name__ == "__main__":
    comprehensive_inspect_and_fix()
