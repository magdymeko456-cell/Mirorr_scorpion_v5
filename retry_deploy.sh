#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

export GOOGLE_APPLICATION_CREDENTIALS="$WORKDIR/serviceAccountKey.json"

echo "=== إعادة محاولة نشر الدالة ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2 \
  --non-interactive

echo "🚀 تم نشر الدالة بنجاح!"
