#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== توليد رابط جديد وسريع لتسجيل الدخول ==="
npx --yes firebase-tools@15.28.1 login --no-localhost
