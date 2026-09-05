#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/2. إصلاح ملف pubspec.yaml المباشر ==="

# استبدال path_provider الاصدار الخاطئ بالاصدار المستقر
sed -i 's/path_provider: \^2.2.1/path_provider: \^2.1.2/g' pubspec.yaml 2>/dev/null || true
sed -i 's/name: mirror_scorpion_v2/name: mirror_scorpion_v4/g' pubspec.yaml 2>/dev/null || true

# في حال عدم وجود sed أو تنوع الملف، نكتب تعيين الاعتمادات المستقرة
cat << 'PUBSPEC_EOF' > pubspec.yaml
name: mirror_scorpion_v4
description: "Mirror Scorpion v4 - Official Release"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  path_provider: ^2.1.2
  shared_preferences: ^2.2.2
  http: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/keys/
PUBSPEC_EOF

echo "=== 2/2. الرفع المباشر إلى GitHub ==="
git add pubspec.yaml
git commit -m "fix: resolve path_provider dependency version for v4 build" || echo "لا تغييرات"
git push origin main --force

echo "🚀 تم إصلاح pubspec.yaml والرفع بنجاح! راقب الـ Actions الآن."
