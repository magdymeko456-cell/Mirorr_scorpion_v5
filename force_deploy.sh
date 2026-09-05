#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

# 1. إزالة أي جلسة دخول قديمة للحساب الشخصي
npx --yes firebase-tools@15.28.1 logout 2>/dev/null || true

# 2. استخراج الـ Private Key و Client Email من الملف وتثبيت البيئة
export GOOGLE_APPLICATION_CREDENTIALS="$WORKDIR/serviceAccountKey.json"

echo "=== نشر الدالة باستخدام حساب الخدمة المباشر ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2 \
  --non-interactive

echo "🚀 تم رفع ونشر الدالة بنجاح!"
