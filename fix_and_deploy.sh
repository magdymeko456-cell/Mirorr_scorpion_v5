#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. البحث عن ملف المفتاح serviceAccountKey.json ==="
KEY_PATH=$(find "$HOME" -maxdepth 3 -name "serviceAccountKey.json" | head -n 1)

if [ -n "$KEY_PATH" ]; then
    echo "✔ تم العثور على الملف في: $KEY_PATH"
    cp "$KEY_PATH" "$WORKDIR/serviceAccountKey.json"
    echo "✔ تم نسخ الملف إلى مجلد المشروع الحالي."
else
    echo "⚠️ لم يتم العثور على serviceAccountKey.json في المجلد المنزلي."
fi

echo "=== 2. بدء عملية التوثيق والنشر ==="
echo "سيتم الآن فتح رابط التوثيق. افتح الرابط في المتصفح، وسجل الدخول بالحساب المالك للمشروع، ثم انسخ الـ Token المطلوب."

npx --yes firebase-tools@15.28.1 login:ci
