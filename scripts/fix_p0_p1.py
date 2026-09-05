import os
import re

def fix_feature_hub():
    file_path = "lib/features/feature_hub_screen.dart"
    
    if not os.path.exists(file_path):
        print(f"❌ خطأ: الملف غير موجود في المسار: {file_path}")
        return

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # إنشاء نسخة احتياطية آمنة
    backup_path = file_path + ".bak"
    with open(backup_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"🛡️ تم إنشاء نسخة احتياطية بنجاح: {backup_path}")

    modified = False

    # 1. إصلاح مايك الحوار وتبديل لغة المصدر عبر استهداف _swapDialogueSpeaker (P0)
    swap_pattern = re.compile(r'(Future<void>\s+_swapDialogueSpeaker\s*\(\s*\)\s*async\s*\{)(.*?)(\bawait\s+_recognitionService\.start\s*\()', re.DOTALL)
    
    def replace_swap(match):
        nonlocal modified
        modified = True
        header, body, start_call = match.groups()
        # إضافة إيقاف مؤكد للمايك قبل بدء الجلسة باللغة الجديدة
        safe_stop = "\n      if (!await _recognitionService.cancelAndWait()) return;\n      await _speechService.stop();\n"
        return header + body + safe_stop + start_call

    content, count_swap = swap_pattern.subn(replace_swap, content)
    if count_swap > 0:
        print("✅ تم تحديث دالة تبديل لغة الحوار والمايك (_swapDialogueSpeaker) بنجاح.")
    else:
        print("⚠️ تنبيه: لم يتم مطابقة نمط _swapDialogueSpeaker حرفياً، جاري المتابعة.")

    if modified:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("🎉 تم تطبيق إصلاحات P0 بنجاح تام وحفظ الملف.")
    else:
        print("ℹ️ لم يتم تعديل إضافي.")

if __name__ == "__main__":
    fix_feature_hub()
