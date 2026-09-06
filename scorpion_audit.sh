#!/usr/bin/env bash
# scorpion_audit.sh — فحص وتشخيص مشروع Flutter (Termux) بدون تعديل أي ملف
# يجمّع: المسارات الحقيقية + إصدارات المكتبات + مواضع ربط المايك/اللغة + أخطاء البناء

set +e   # لا نتوقف عند أي خطأ، نجمع أكبر قدر من المعلومات

OUT=~/scorpion_audit_$(date +%Y%m%d_%H%M%S).log
echo "سيُحفظ التقرير في: $OUT"

# ---------- محاولة العثور على جذر المشروع ----------
if [ -n "$1" ] && [ -d "$1" ]; then
  PROJ="$1"
elif [ -d ./lib ] && [ -f ./pubspec.yaml ]; then
  PROJ="$(pwd)"
elif [ -d ~/Mirorr_scorpion_v5 ] && [ -f ~/Mirorr_scorpion_v5/pubspec.yaml ]; then
  PROJ=~/Mirorr_scorpion_v5
elif [ -d ~/mirror_scorpion_v4 ] && [ -f ~/mirror_scorpion_v4/pubspec.yaml ]; then
  PROJ=~/mirror_scorpion_v4
else
  echo "لم أجد جذر المشروع تلقائيًا."; echo "مرّر المسار كوسيط: bash scorpion_audit.sh /path/to/project"
  exit 1
fi
echo "جذر المشروع المحدد: $PROJ"

echo "===== [1] البيئة =====" | tee -a "$OUT"
echo "--- إصدار Flutter ---" | tee -a "$OUT"
flutter --version 2>&1 | tee -a "$OUT"
echo "--- إصدار Dart ---" | tee -a "$OUT"
dart --version 2>&1 | tee -a "$OUT"

echo "===== [2] معلومات git =====" | tee -a "$OUT"
cd "$PROJ" || exit 1
echo "--- الفرع الحالي والحالة ---" | tee -a "$OUT"
git branch --show-current 2>&1 | tee -a "$OUT"
git status --short 2>&1 | tee -a "$OUT"
echo "--- الـ remotes ---" | tee -a "$OUT"
git remote -v 2>&1 | tee -a "$OUT"
echo "--- آخر 5 commits ---" | tee -a "$OUT"
git log --oneline -5 2>&1 | tee -a "$OUT"

echo "===== [3] البنية العليا للمشروع =====" | tee -a "$OUT"
ls -la "$PROJ" | tee -a "$OUT"
echo "--- شجرة lib (بدون تفاصيل) ---" | tee -a "$OUT"
find lib -type d 2>/dev/null | tee -a "$OUT"
echo "--- كل ملفات .dart وعددها ---" | tee -a "$OUT"
find lib -name "*.dart" 2>/dev/null | tee -a "$OUT"
echo "عدد ملفات dart:" $(find lib -name "*.dart" 2>/dev/null | wc -l) | tee -a "$OUT"

echo "===== [4] pubspec.yaml كامل =====" | tee -a "$OUT"
sed -n '1,400p' pubspec.yaml 2>&1 | tee -a "$OUT"

echo "===== [5] شجرة الاعتماديات (إن أمكن) =====" | tee -a "$OUT"
(timeout 120 flutter pub deps --style=compact 2>&1) | tee -a "$OUT"

echo "===== [6] مواضع ربط المايك/اللغة والترجمة الصوتية =====" | tee -a "$OUT"
echo "--- كل مراجع speech_to_text / التعرف الصوتي ---" | tee -a "$OUT"
grep -rn "speech_to_text\|SpeechToText\|_speechToText" lib 2>/dev/null | tee -a "$OUT"
echo "--- كل مراجع SpeechLocaleResolver والحقول المرتبطة ---" | tee -a "$OUT"
grep -rn "SpeechLocaleResolver\|preferredLocaleId\|installedLocaleIds\|availableLanguageCodes\|\.locales()" lib 2>/dev/null | tee -a "$OUT"
echo "--- مراجع لغة الجهاز وربطها بالمايك ---" | tee -a "$OUT"
grep -rn "deviceLanguage\|LanguagePreferences\|deviceLanguageCode\|LanguageCode\|intl\|flutter_localizations\|supportedLocales" lib 2>/dev/null | tee -a "$OUT"
echo "--- مراجع ML Kit ---" | tee -a "$OUT"
grep -rn "google_mlkit\|GoogleMlKit\|TextRecognizer\|mlkit" lib pubspec.yaml 2>/dev/null | tee -a "$OUT"
echo "--- كل استدعاءات تسجيل/بدء صوت (سياق مواضعها) ---" | tee -a "$OUT"
grep -rn "start(\|listen(\|onText\|languageCode\|language=" lib 2>/dev/null | tee -a "$OUT"

echo "===== [7] الملفات الرئيسية المعنية =====" | tee -a "$OUT"
echo "--- قائمة الملفات التي تحتوي ترجمة صوتية ---" | tee -a "$OUT"
grep -rln "speech_to_text\|SpeechLocaleResolver\|SpeechToText" lib 2>/dev/null | tee -a "$OUT"

echo "===== [8] محاولة بناء تشخيصي (Debug APK) — قد يستغرق وقتًا =====" | tee -a "$OUT"
echo "سأحاول البناء؛ إن فشل ستظهر الأخطاء هنا." | tee -a "$OUT"
(timeout 900 flutter build apk --debug 2>&1) | tee -a "$OUT"
echo "--- الأخطاء فقط (filtered) ---" | tee -a "$OUT"
(timeout 900 flutter build apk --debug 2>&1) | grep -iE "error|exception|failed|conflict|version|requires|not found|cannot|unresolved" | tee -a "$OUT"

echo "===== انتهى الفحص =====" | tee -a "$OUT"
echo ""
echo "التقرير الكامل محفوظ في: $OUT"
echo "انسخ محتوى هذا الملف كاملًا وأعده لي في المحادثة."
