#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. بدء جلسة التوثيق وسيتم فتح المتصفح تلقائياً ==="

# تشغيل أمر الدخول في الخلفية لالتقاط الرابط وفتحه تلقائياً عبر Termux
npx --yes firebase-tools@15.28.1 login --no-localhost | while IFS= read -r line; do
    echo "$line"
    if [[ "$line" =~ https://auth\.firebase\.tools/login\?.* ]]; then
        URL=$(echo "$line" | grep -o 'https://auth\.firebase\.tools/login?[^ ]*')
        echo ""
        echo "🚀 جاري فتح المتصفح تلقائياً..."
        termux-open-url "$URL" 2>/dev/null || am start -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 || true
    fi
done

echo "=== 2. جاري نشر الدالة بعد نجاح التوثيق ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2

echo "🚀 تم نشر الدالة بنجاح!"
