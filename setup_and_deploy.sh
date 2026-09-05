#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

export GOOGLE_APPLICATION_CREDENTIALS="$WORKDIR/serviceAccountKey.json"

echo "=== 1/2. تفعيل Cloud Resource Manager API ==="
# محاولة تفعيل الخدمة باستخدام gcloud إذا كانت متوفرة
gcloud services enable cloudresourcemanager.googleapis.com cloudfunctions.googleapis.com build.googleapis.com --project mirorr-d11b2 2>/dev/null || true

echo "=== 2/2. إعادة محاولة نشر الدالة ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2 \
  --non-interactive

echo "🚀 تم نشر الدالة بنجاح!"
