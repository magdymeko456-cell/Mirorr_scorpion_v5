#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. توليد الجلسة وفتح المتصفح تلقائياً ==="
# نفتح الرابط تلقائياً باستخدام termux-open-url
URL=$(npx --yes firebase-tools@15.28.1 login --no-localhost 2>&1 | grep -o 'https://auth\.firebase\.tools/login?[^ ]*' | head -n 1) || true

if [ -n "$URL" ]; then
    echo "🚀 جاري فتح المتصفح..."
    termux-open-url "$URL" 2>/dev/null || am start -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 || true
fi

echo "=== 2. تشغيل عملية الدخول ==="
npx --yes firebase-tools@15.28.1 login --no-localhost

echo "=== 3. نشر الدالة ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2

echo "🚀 تم نشر الدالة بنجاح!"
