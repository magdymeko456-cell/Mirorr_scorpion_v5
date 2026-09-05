#!/usr/bin/env bash
set -Eeuo pipefail

# Mirror Scorpion repair gate: inspect first, then optionally run checks.
# Usage: ./scripts/repair_gate.sh [--check]

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

if [[ ! -f pubspec.yaml || ! -d lib ]]; then
  echo "ERROR: this script must run from the Mirror Scorpion project directory: $ROOT" >&2
  echo "Expected pubspec.yaml and lib/ beside scripts/." >&2
  exit 1
fi

if [[ ! -d .git ]]; then
  echo 'WARN no .git directory found; running from a transferred source archive.'
fi

fail=0
printf '%s\n' 'Mirror Scorpion v5 repair gate'
printf 'root: %s\n' "$ROOT"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'branch: '; git branch --show-current
  printf 'commit: '; git rev-parse --short HEAD
  HAS_GIT=1
else
  echo 'branch: <source archive>'
  echo 'commit: <not available>'
  HAS_GIT=0
fi

printf '%s\n' $'\n[1/4] repository state'
if (( HAS_GIT )); then
  if [[ -n "$(git status --porcelain)" ]]; then
    git status --short
  else
    echo 'clean working tree'
  fi
else
  echo 'source archive; Git working-tree status unavailable'
fi

printf '%s\n' $'\n[2/4] required Flutter project files'
for path in pubspec.yaml lib test assets; do
  if [[ -e "$path" ]]; then echo "OK   $path"; else echo "MISS $path"; fail=1; fi
done
if [[ -d android ]]; then
  echo 'OK   android'
else
  echo 'WARN android platform directory is absent; generate it with Flutter before an Android build.'
fi

printf '%s\n' $'\n[3/4] credential scan'
if grep -RInE --exclude-dir=.git --exclude='*.lock' \
  -e 'ghp_[A-Za-z0-9]{20,}' -e 'github_pat_[A-Za-z0-9_]{20,}' \
  -e 'AIza[0-9A-Za-z_-]{20,}' -e 'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY' \
  -e 'sk-[A-Za-z0-9]{20,}' .; then
  echo 'ERROR: possible credential found; remove it and rotate it before pushing.'
  fail=1
else
  echo 'no supported credential patterns found'
fi

printf '%s\n' $'\n[4/4] toolchain'
if command -v flutter >/dev/null 2>&1; then
  flutter --version | head -8
  if [[ "${1:-}" == "--check" ]]; then
    flutter pub get
    flutter analyze
    flutter test
  else
    echo 'Flutter checks not run; pass --check after installing Flutter.'
  fi
else
  echo 'Flutter is not installed in this environment; source checks deferred.'
  if [[ "${1:-}" == "--check" ]]; then
    echo 'ERROR: --check requires Flutter. Install Flutter, then run this command again.'
    fail=1
  fi
fi

if (( fail )); then
  echo 'REPAIR_GATE: FAILED'
  exit 1
fi
echo 'REPAIR_GATE: PASSED'
