#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. جاري بدء جلسة الدخول وتوجيه المتصفح تلقائياً ==="

# فتح الرابط في الخلفية فور ظهوره لمنع تكرار فتح جلسات جديدة
(
  sleep 3
  LOG_FILE="/tmp/firebase_login.log"
  if [ -f "$LOG_FILE" ]; then
    URL=$(grep -o 'https://auth\.firebase\.tools/login?[^ ]*' "$LOG_FILE" | head -n 1 || true)
    if [ -n "$URL" ]; then
      echo -e "\n🚀 جاري فتح المتصفح تلقائياً..."
      termux-open-url "$URL" 2>/dev/null || am start -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 || true
    fi
  fi
) &

# تشغيل أمر الدخول الفردي مع حفظ المخرجات لالتقاط الرابط
npx --yes firebase-tools@15.28.1 login --no-localhost | tee /tmp/firebase_login.log

echo "=== 2. جاري نشر الدالة ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2

echo "🚀 تم رفع ونشر الدالة بنجاح!"
