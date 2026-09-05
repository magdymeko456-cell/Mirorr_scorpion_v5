#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. تسجيل الدخول إلى Firebase ==="
npx --yes firebase-tools@15.28.1 login --no-localhost

echo "=== 2. بدء نشر الدالة ==="
npx --yes firebase-tools@15.28.1 deploy \
  --only functions:healthCheck \
  --project mirorr-d11b2

echo "🚀 تم نشر الدالة بنجاح!"
