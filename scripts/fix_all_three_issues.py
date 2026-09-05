import os

path = "lib/features/feature_hub_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. التأكد من وجود زر سريع لفتح الشطرنج إذا لم يكن مربوطاً ببطاقة الألعاب
    # 2. إضافة زر استدعاء شيت الأصوات الخمسة (VoiceSelectionSheet) بجانب أدوات الصوت
    # 3. تحسين استجابة المايك وتعليقات الحالة (Notice)

    target_audio_action = "_EditorAction(icon: Icons.ios_share,"
    patch_voices_button = """_EditorAction(
                    icon: Icons.record_voice_over,
                    tooltip: 'اختيار الأصوات الخمسة (تامر، سيف، سلمى، سما، سارة)',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => VoiceSelectionSheet(voiceService: _speechService),
                      );
                    },
                  ),
                  _EditorAction(icon: Icons.ios_share,"""

    if "VoiceSelectionSheet" not in content and target_audio_action in content:
        content = content.replace(target_audio_action, patch_voices_button)
        # استيراد ملف شيت الأصوات إذا لم يكن موجوداً
        if "voice_selection_sheet.dart" not in content:
            content = "import '../audio/voice_selection_sheet.dart';\n" + content
        print("✅ تم حقن زر اختيار الأصوات الخمسة بنجاح.")

    # تحسين دالة المايك لضمان ظهور حالة الخطأ أو الاستماع بوضوح
    mic_target = "Future<void> _toggleMicrophone() async {"
    mic_patch = """Future<void> _toggleMicrophone() async {
    setState(() => _notice = 'جارٍ تفعيل المايك واستماع الصوت...');"""
    
    if mic_target in content and "جارٍ تفعيل المايك" not in content:
        content = content.replace(mic_target, mic_patch)
        print("✅ تم تحسين تفاعل المايك ورسائل التنبيه الفورية.")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ اكتمل التدخل الجراحي البرمجي في الملف الرئيسي بنجاح.")
else:
    print("❌ الملف غير موجود.")
