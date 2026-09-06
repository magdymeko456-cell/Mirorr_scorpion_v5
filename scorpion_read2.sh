#!/usr/bin/env bash
set +e
OUT=~/scorpion_read2_$(date +%Y%m%d_%H%M%S).log
PROJ=~/Mirorr_scorpion_v5
echo "سيُحفظ في: $OUT"

echo "===== [1] تحديد مسار flutter =====" | tee -a "$OUT"
echo "--- PATH الحالي ---" | tee -a "$OUT"
echo "$PATH" | tr ':' '\n' | tee -a "$OUT"
echo "--- تجربة بعد تحميل ملفات الإعداد ---" | tee -a "$OUT"
[ -f ~/.bashrc ] && . ~/.bashrc
[ -f ~/.profile ] && . ~/.profile
command -v flutter && flutter --version 2>&1 | tee -a "$OUT"
echo "--- بحث محدود عن flutter (قد يستغرق لحظات) ---" | tee -a "$OUT"
find "$HOME" -maxdepth 5 -type f -name flutter 2>/dev/null | tee -a "$OUT"
ls -d "$HOME"/flutter* "$HOME"/flutter*/bin 2>/dev/null | tee -a "$OUT"
echo "--- محتوى سكربتات الإعداد لديك (تكشف كيف تُشغّل flutter عادة) ---" | tee -a "$OUT"
for f in termux_setup_mirror_scorpion_v5.sh termux_prepare_flutter_v4.sh auto_deploy.sh; do
  echo "### $f ###"; cat "$PROJ/$f" 2>/dev/null | tee -a "$OUT"; echo
done

echo "===== [2] ملف التعرف الصوتي كاملًا (المرجع الأساسي للخطأ) =====" | tee -a "$OUT"
sed -n '1,260p' "$PROJ/lib/core/speech/device_speech_recognition_service.dart" | tee -a "$OUT"

echo "===== [3] مواضع بدء المايك في حوار الترجمة (feature_hub_screen) =====" | tee -a "$OUT"
echo "--- منطقة بدء المايك الأولى (حول سطر 440-520) ---" | tee -a "$OUT"
sed -n '440,525p' "$PROJ/lib/features/feature_hub_screen.dart" | tee -a "$OUT"
echo "--- منطقة بدء المايك الثانية (حول سطر 880-1010) ---" | tee -a "$OUT"
sed -n '875,1015p' "$PROJ/lib/features/feature_hub_screen.dart" | tee -a "$OUT"
echo "--- منطقة كارت الحوار والتحويل (حول سطر 3420-3520) ---" | tee -a "$OUT"
sed -n '3420,3520p' "$PROJ/lib/features/feature_hub_screen.dart" | tee -a "$OUT"

echo "===== [4] فحص التوكنات المكشوفة في التاريخ والمستودع =====" | tee -a "$OUT"
cd "$PROJ" || exit 1
echo "--- أي توكنات ghp_ داخل الملفات المراقبة ---" | tee -a "$OUT"
grep -rn "ghp_\|github_pat_" --include="*.sh" --include="*.py" --include="*.md" --include="*.dart" --include="*.yaml" . 2>/dev/null | head -40 | tee -a "$OUT"

echo "===== انتهى =====" | tee -a "$OUT"
echo "التقرير: $OUT — انسخه كاملًا وأعده لي."
