import os

path = "lib/features/feature_hub_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # التأكد من استيراد خدمة الأصوات
    if "voice_selection_service.dart" not in content:
        content = "import '../core/services/voice_selection_service.dart';\n" + content

    # البحث عن استدعاء VoiceSelectionSheet وتمرير VoiceSelectionService بالشكل الصحيح أو إنشاء مثيل عام متوافق
    old_sheet_call = "builder: (_) => VoiceSelectionSheet(voiceService: VoiceSelectionService()..initialize()),"
    
    # بدلاً من ذلك، سننشئ محدد صوت متوافق أو نستخدم المزود (Provider) إذا وجد، 
    # أو نمرر _speechService إذا قمنا بتعديل الشيت ليدقبل SystemTtsService أو نمط مشترك.
    # الحل الأضمن والأبسط جراحياً: تعديل VoiceSelectionSheet ليقبل SystemTtsService مباشرة أو إنشاء متغير مرن.
