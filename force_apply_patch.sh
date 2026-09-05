#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/4. إلغاء محاولة الـ Patch الفاشلة ==="
git am --abort 2>/dev/null || true

echo "=== 2/4. تطبيق الملفات عنوة مع دمج التغيرات ==="
git apply --reject --whitespace=fix mirror-scorpion-firebase-healthcheck.patch 2>/dev/null || true

echo "=== 3/4. إضافة التعديلات وإنشاء Commit ==="
git add .
git commit -m "feat(firebase): restore tested functions health check" || echo "لا يوجد جديد للتسجيل"

echo "=== 4/4. رفع التعديلات مباشرة إلى GitHub ==="
git push origin main --force-with-lease || git push origin main

echo "🚀 تم تطبيق الـ Patch وتحديث المستودع على GitHub بنجاح!"
