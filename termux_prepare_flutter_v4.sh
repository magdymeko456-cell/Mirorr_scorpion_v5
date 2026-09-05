#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

WORKDIR="${MIRROR_WORKDIR:-$HOME/mirror_scorpion_v4}"
PROJECT_DIR="$WORKDIR/flutter_v4"

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter غير متاح في Termux. استخدم Termux للتحرير والرفع فقط، واترك بناء APK إلى GitHub Actions.' >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
  echo "ملف pubspec.yaml غير موجود في: $PROJECT_DIR" >&2
  exit 1
fi

if find "$PROJECT_DIR" -type f \( -iname '*.pem' -o -iname '*.jks' -o -iname '*.keystore' -o -iname '*.p12' \) -print | grep -q .; then
  echo 'توقف آمن: توجد مادة مفاتيح داخل مشروع Flutter.' >&2
  exit 1
fi

cd "$PROJECT_DIR"
flutter create --platforms=android --project-name mirror_scorpion_v4 .
flutter pub get
flutter analyze
flutter test

echo 'نجحت تهيئة Flutter محلياً. لا تنفذ git push قبل مراجعة التغييرات ونجاح الاختبارات.'
