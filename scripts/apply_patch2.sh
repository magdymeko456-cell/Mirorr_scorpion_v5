#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE=check
RUN_FLUTTER=0
ALLOW_DIRTY=0
for arg in "$@"; do
  case "$arg" in
    --apply) MODE=apply ;;
    --check) MODE=check ;;
    --run-flutter) RUN_FLUTTER=1 ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    -h|--help)
      echo "Usage: scripts/apply_patch2.sh [--check|--apply] [--run-flutter] [--allow-dirty]"
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

[[ -f pubspec.yaml && -d lib ]] || { echo "Flutter project not found: $ROOT" >&2; exit 1; }

require_file() { [[ -f "$1" ]] || { echo "Missing: $1" >&2; exit 1; }; }
require_text() {
  grep -qE "$2" "$1" || { echo "Missing $3 in $1" >&2; exit 1; }
}

require_file lib/features/feature_hub_screen.dart
require_file lib/core/platform/android_overlay_service.dart
require_file lib/core/mlkit/on_device_translation_service.dart
require_file lib/core/content/offline_content_storage.dart
require_file lib/core/games/chess_game_controller.dart
require_text lib/features/feature_hub_screen.dart 'class _GamesPanel' 'chess panel'
require_text lib/features/feature_hub_screen.dart 'class _OfflinePackagesPage' 'offline language page'
require_text lib/features/feature_hub_screen.dart '_prepareTranslationModels|_downloadPackage' 'language download action'
require_text lib/core/platform/android_overlay_service.dart 'showBubble|_OverlayBubble' 'floating bubble'
require_text lib/core/mlkit/on_device_translation_service.dart 'downloadModel\(' 'ML Kit download'
require_text lib/core/games/chess_game_controller.dart 'class ChessGameController' 'chess controller'

if [[ "$MODE" == check ]]; then
  echo "Patch 2 check passed; no files changed."
  exit 0
fi

if [[ "$ALLOW_DIRTY" -eq 0 && -n "$(git status --porcelain)" ]]; then
  echo "Worktree is dirty. Use --allow-dirty or commit/stash first." >&2
  git status --short >&2
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP="backup/patch2-$STAMP"
git branch "$BACKUP"
echo "Rollback branch: $BACKUP"

touch .gitignore
for item in 'fix_*.txt' 'clean_failed_runs.sh' 'repo_review_*.txt' 'patch2_*.log' 'patch2_backup_*/'; do
  grep -qxF "$item" .gitignore || printf '%s\n' "$item" >> .gitignore
done

git add .gitignore
if ! git diff --cached --quiet; then
  git commit -m "chore(P2): protect patch diagnostics from tracking"
fi

if [[ "$RUN_FLUTTER" -eq 1 ]]; then
  command -v flutter >/dev/null || { echo "flutter is not installed or not on PATH" >&2; exit 1; }
  flutter pub get
  flutter analyze
  flutter test
else
  echo "Flutter checks skipped; use --run-flutter to run them."
fi

echo "Patch 2 completed locally. Push with: git push origin main"
