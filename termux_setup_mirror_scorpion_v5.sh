#!/usr/bin/env bash
set -Eeuo pipefail

# Creates an isolated Termux folder and clones the project into it.
# Run this file from any directory with: bash termux_setup_mirror_scorpion_v5.sh

PROJECT_NAME="Mirorr_scorpion_v5"
REPO_URL="https://github.com/magdymeko456-cell/Mirorr_scorpion_v5.git"
PROJECT_DIR="${HOME}/${PROJECT_NAME}"

if ! command -v git >/dev/null 2>&1; then
  echo 'ERROR: git is not installed.' >&2
  echo 'Install it with: pkg update -y && pkg install git -y' >&2
  exit 1
fi

if [[ -e "$PROJECT_DIR" && ! -d "$PROJECT_DIR/.git" ]]; then
  echo "ERROR: $PROJECT_DIR exists but is not a Git checkout." >&2
  echo 'Nothing was changed. Rename or move that folder manually, then run again.' >&2
  exit 1
fi

if [[ -d "$PROJECT_DIR/.git" ]]; then
  current_url="$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$current_url" != "$REPO_URL" ]]; then
    echo "ERROR: $PROJECT_DIR belongs to a different repository:" >&2
    echo "       ${current_url:-<no origin>}" >&2
    exit 1
  fi
  git -C "$PROJECT_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"
chmod +x scripts/repair_gate.sh
echo
echo "Project directory: $PROJECT_DIR"
echo 'The repository is isolated; no files were mixed with another Termux folder.'
echo
echo 'Running the repair gate:'
bash scripts/repair_gate.sh
echo
echo 'Next commands:'
echo "  cd '$PROJECT_DIR'"
echo '  bash scripts/repair_gate.sh --check'
