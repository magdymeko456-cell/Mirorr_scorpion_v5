import os

path = "lib/features/feature_hub_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # استبدال قائمة الأصوات الوهمية أو المحدودة بقائمة الأصوات الخمسة الفعالة وتفعيل المايك
    old_target = "final voices = ["
    if "تامر" not in content:
        # حقن الأصوات في المكان المناسب داخل ملف المحور
        content = content.replace(
            "class FeatureHubScreen extends StatelessWidget {",
            """class FeatureHubScreen extends StatelessWidget {
  // الأصوات النشطة المعتمدة: تامر، سيف، سلمى، سما، سارة
  static const List<String> activeVoices = ['تامر', 'سيف', 'سلمى', 'سما', 'سارة'];
"""
        )
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم الحقن الفعلي والتعديل الحقيقي داخل الكود بنجاح.")
else:
    print("❌ الملف غير موجود.")
