#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/4. إلغاء محاولة الـ Patch الفاشلة ==="
git am --abort 2>/dev/null || true

echo "=== 2/4. حذف مجلد node_modules وملفات الـ Patch المؤقتة ==="
rm -rf node_modules
rm -f *.patch

echo "=== 3/4. حفظ التعديلات وإلغاء تتبع الملفات المحذوفة ==="
git add -A
git commit -m "chore(repo): remove generated node modules and patch residue" || echo "لا توجد تغييرات جديدة للتسجيل"

echo "=== 4/4. رفع التعديلات النهائية إلى GitHub ==="
git push origin main

echo "🚀 تم التنظيف والرفع بنجاح يا بطل!"
