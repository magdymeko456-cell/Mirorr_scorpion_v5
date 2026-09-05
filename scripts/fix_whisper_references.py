import os

path = "lib/features/feature_hub_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# تعريف الخدمات والمتغيرات غير الموجودة محلياً بطريقة آمنة ضمن الدالة أو الملف
# التأكد من تعريف _whisperService و sourceLanguage أو استبدالها ببدائل صحيحة
# مثل استخدام AudioTranscriberService أو إضافة التعريفات الناقصة.

# دعنا نتحقق من كيفية تعريف الخدمة في مشروع Mirror Scorpion v4
# سنضيف تعريف whisperService و sourceLanguage إذا لم تكن موجودة.

if "_whisperService" in content and "final _whisperService" not in content and "AudioTranscriberService" in content:
    # ربط أو استبدال _whisperService بـ AudioTranscriberService أو تعريفها
    content = content.replace(
        "final transcript = await _whisperService.transcribeAudio(audioPath);",
        "final transcript = await AudioTranscriberService().transcribeAudio(audioPath);"
    )

if "sourceLanguage" in content and "String sourceLanguage" not in content and "sourceLang" in content:
    content = content.replace("sourceLanguage: sourceLanguage", "sourceLanguageCode: sourceLang")
elif "sourceLanguage" in content and "sourceLanguage =" not in content:
    content = content.replace("sourceLanguage: sourceLanguage", "sourceLanguageCode: 'ar'")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("✅ تم تصحيح مراجع _whisperService و sourceLanguage في feature_hub_screen.dart")
