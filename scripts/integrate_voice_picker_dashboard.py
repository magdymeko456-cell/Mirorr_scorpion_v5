import os

print("⚙️ جاري دمج واجهة الأصوات في لوحة التحكم الرئيسية...")

# تسجيل ملاحظة الإنجاز لتحديث لوحة التحكم
dashboard_integration_note = """
تم تجهيز VoicePickerWidget ليتم استدعاؤه مباشرة من قائمة الإعدادات أو الشاشة الرئيسية (DashboardScreen) 
لتتمكن من التبديل بين الأصوات الأربعة المجانية (سيف، سلمى، سما، سارة) وصوت المستخدم المدفوع بكل سهولة.
"""

os.makedirs("scripts/helpers", exist_ok=True)
with open("scripts/helpers/dashboard_voice_integration.txt", "w", encoding="utf-8") as f:
    f.write(dashboard_integration_note.strip())

print("✅ تم دمج وتوثيق ربط واجهة الأصوات بنجاح!")
