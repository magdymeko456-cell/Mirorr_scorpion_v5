#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
DOWNLOAD_DIR="/sdcard/Download"

echo "=== 1. التأكد من صلاحية الوصول للتخزين ==="
termux-setup-storage 2>/dev/null || true

echo "=== 2. البحث عن أحدث مفتاح تم تحميله ==="
# البحث عن آخر ملف json تم تحميله
LATEST_KEY=$(ls -t "$DOWNLOAD_DIR"/*.json 2>/dev/null | head -n 1)

if [ -z "$LATEST_KEY" ]; then
    echo "⚠️ لم أجد أي ملف .json في مجلد التحميلات، تأكد من وجوده."
    exit 1
fi

echo "✅ تم العثور على: $(basename "$LATEST_KEY")"

echo "=== 3. نقل الملف إلى مجلد المشروع ==="
cp "$LATEST_KEY" "$WORKDIR/serviceAccountKey.json"
echo "تم نسخ الملف وتسميته بنجاح: serviceAccountKey.json"

echo "=== 4. اختبار الاتصال ==="
cd "$WORKDIR"
node test_firebase.js
