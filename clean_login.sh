#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== بدء عملية تسجيل الدخول ==="
# سنشغل الدخول مباشرة لضمان عدم تغير رقم الجلسة
npx --yes firebase-tools@15.28.1 login --no-localhost
