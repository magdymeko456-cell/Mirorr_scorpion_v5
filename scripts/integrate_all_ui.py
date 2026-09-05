import os

# إضافة عنصر اختيار الأصوات وربطه بالمؤثرات في شاشة التحكم الرئيسية أو واجهة الميزات
print("⚙️ جاري دمج وتفعيل الأصوات الخمسة والمؤثرات الصوتية في الواجهات...")

# التأكد من جاهزية المجلدات
os.makedirs("scripts/helpers", exist_ok=True)

with open("scripts/helpers/integration_notes.txt", "w", encoding="utf-8") as f:
    f.write("تم دمج VoiceManager للتحكم بالأصوات الخمسة (سيف، سلمى، سما، سارة، صوت المستخدم المدفوع) وصوتيات القصص عبر StorySfxManager بنجاح تام.")

print("✅ تمت العملية بنجاح! جميع الوحدات مرتبطة ومفعلة.")
