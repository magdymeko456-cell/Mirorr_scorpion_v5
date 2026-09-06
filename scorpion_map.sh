#!/usr/bin/env bash
OUT=~/scorpion_map_$(date +%Y%m%d_%H%M%S).log
echo "سيُحفظ في: $OUT"

echo "===== [1] كل مجلدات المشروع تحت home =====" | tee -a "$OUT"
find "$HOME" -maxdepth 2 -name pubspec.yaml 2>/dev/null | while read -r f; do
  d="$(dirname "$f")"
  echo "--- المجلد: $d ---" | tee -a "$OUT"
  echo "اسم الحزمة: $(grep -m1 '^name:' "$f")" | tee -a "$OUT"
  cd "$d" 2>/dev/null && echo "remote: $(git remote get-url origin 2>&1)" | tee -a "$OUT"
  cd "$HOME" || exit 1
done

echo "===== [2] أي مجلدات تدعى v4/v5/مرآة =====" | tee -a "$OUT"
find "$HOME" -maxdepth 2 -type d \( -iname "*scorpion*" -o -iname "*mirror*" -o -iname "*v4*" -o -iname "*v5*" \) 2>/dev/null | tee -a "$OUT"

echo "===== [3] حال كل مستودع وتفرّعه =====" | tee -a "$OUT"
for d in "$HOME"/Mirorr_scorpion_v5 "$HOME"/mirror_scorpion_v4; do
  if [ -d "$d/.git" ]; then
    echo "### $d ###" | tee -a "$OUT"
    git -C "$d" remote -v | tee -a "$OUT"
    echo "الفرع: $(git -C "$d" branch --show-current)" | tee -a "$OUT"
    echo "آخر commit محلي:"; git -C "$d" log -1 --format='%h %s' 2>&1 | tee -a "$OUT"
    echo "آخر commit بعيد (fetch):" | tee -a "$OUT"
    git -C "$d" fetch origin -q 2>/dev/null
    git -C "$d" log -1 --format='%h %s' origin/"$(git -C "$d" branch --show-current)" 2>&1 | tee -a "$OUT"
    echo "تعديلات غير مرفوعة: $(git -C "$d" status --porcelain | wc -l)" | tee -a "$OUT"
  fi
done

echo "===== [4] فحص أي توكن ghp_ في كل سكربتات الرفع =====" | tee -a "$OUT"
grep -rn "ghp_\|github_pat_" "$HOME" --include="*.sh" 2>/dev/null | grep -v "\.log" | head -30 | tee -a "$OUT"

echo "===== انتهى =====" | tee -a "$OUT"
echo "التقرير: $OUT"
