#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MODE=check

case "${1:---check}" in
  --check) MODE=check ;;
  --test) MODE=test ;;
  --build) MODE=build ;;
  --install) MODE=install ;;
  *) echo "Usage: $0 [--check|--test|--build|--install]"; exit 2 ;;
esac

need() {
  test -f "$1" || { echo "FAIL: missing $1"; exit 1; }
}
has() {
  grep -qE "$2" "$1" || { echo "FAIL: missing $3 in $1"; exit 1; }
  echo "PASS: $3"
}

need lib/features/chess_club_screen.dart
need lib/core/games/chess_game_controller.dart
need lib/core/platform/android_overlay_service.dart
need lib/core/mlkit/on_device_translation_service.dart
need lib/core/content/github_content_catalog_service.dart
need lib/features/feature_hub_screen.dart
need lib/features/home/dashboard_screen.dart
need lib/l10n/app_en.arb
need l10n.yaml

has lib/features/chess_club_screen.dart 'class ChessClubScreen' 'ChessClubScreen'
has lib/core/games/chess_game_controller.dart 'class ChessGameController' 'ChessGameController'
has lib/core/platform/android_overlay_service.dart 'showBubble\\(' 'floating bubble'
has lib/core/platform/android_overlay_service.dart 'FlutterOverlayWindow' 'overlay window'
has lib/core/mlkit/on_device_translation_service.dart 'downloadModel\\(' 'ML Kit language download'
has lib/features/feature_hub_screen.dart '_prepareTranslationModels|_downloadPackage' 'language download UI'
has lib/features/home/dashboard_screen.dart 'AppLocalizations|_featuresFor' 'localized dashboard cards'
has lib/l10n/app_en.arb 'translationCardTitle' 'English fallback'

echo 'Patch 3 static check passed.'

if [ "$MODE" = check ]; then
  exit 0
fi

command -v flutter >/dev/null 2>&1 || {
  echo 'FAIL: Flutter is not installed or not in PATH.'
  echo 'Run --test/--build on the cloud Flutter runner, not in this Termux editor.'
  exit 1
}

flutter gen-l10n
flutter pub get
flutter analyze
flutter test

if [ "$MODE" = build ] || [ "$MODE" = install ]; then
  flutter build apk --release
  APK=build/app/outputs/flutter-apk/app-release.apk
  test -f "$APK" || { echo "FAIL: APK not found: $APK"; exit 1; }
  sha256sum "$APK"
fi

if [ "$MODE" = install ]; then
  command -v adb >/dev/null 2>&1 || { echo 'FAIL: adb is not installed or not in PATH.'; exit 1; }
  adb get-state
  adb install -r build/app/outputs/flutter-apk/app-release.apk
fi

echo "Patch 3 $MODE completed successfully."
