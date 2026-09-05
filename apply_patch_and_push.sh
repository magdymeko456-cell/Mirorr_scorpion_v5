#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/4. تنظيف وإلغاء أي تعارضات معلقة ==="
git rebase --abort 2>/dev/null || true
git merge --abort 2>/dev/null || true

echo "=== 2/4. تنزيل ملف الـ Patch ==="
curl -L 'https://files.manuscdn.com/user_upload_by_module/session_file/310419663026888346/uXjgnBFzMJVibvaF.patch' \
  -o mirror-scorpion-firebase-healthcheck.patch

echo "=== 3/4. تطبيق الـ Patch وتضمينه ==="
git am mirror-scorpion-firebase-healthcheck.patch || (git apply mirror-scorpion-firebase-healthcheck.patch && git add . && git commit -m "apply firebase healthcheck patch")

echo "=== 4/4. رفع التعديلات إلى GitHub ==="
git push origin main

echo "🚀 تم تطبيق الـ Patch ورفع التعديلات بنجاح تام يا صديقي!"
