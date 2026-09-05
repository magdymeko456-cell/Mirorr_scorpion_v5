#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

export GOOGLE_APPLICATION_CREDENTIALS="$WORKDIR/serviceAccountKey.json"

# استخراج إيميل حساب الخدمة والمفتاح الخاص لاستخدامه مباشرة
CLIENT_EMAIL=$(jq -r '.client_email' "$WORKDIR/serviceAccountKey.json")
echo "=== استخدام حساب الخدمة: $CLIENT_EMAIL ==="

# تفعيل النشر المباشر عبر Google Application Credentials
export FIREBASE_TOKEN=""

npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2 \
  --non-interactive

echo "🚀 تم رفع ونشر الدالة بنجاح!"
