#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/3. سحب التعديلات من GitHub ودمجها ==="
git pull origin main --rebase || git pull origin main --no-rebase

echo "=== 2/3. التأكد من حالة المستودع ==="
git status

echo "=== 3/3. رفع التعديلات النهائية ==="
git push origin main

echo "🚀 تم الدمج والرفع إلى GitHub بنجاح تام!"
