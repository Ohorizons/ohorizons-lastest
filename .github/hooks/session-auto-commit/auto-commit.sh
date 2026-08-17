#!/bin/bash

# Session Auto-Commit Hook
# Automatically commits and pushes changes when a Copilot session ends

set -euo pipefail

# Consume the Copilot hook payload; this hook acts on repository state.
INPUT=$(cat || true)

# Check if SKIP_AUTO_COMMIT is set
if [[ "${SKIP_AUTO_COMMIT:-}" == "true" ]]; then
  echo "[SKIP] Auto-commit skipped (SKIP_AUTO_COMMIT=true)"
  exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "[WARN] Not in a git repository"
  exit 0
fi

# Check for uncommitted changes
if [[ -z "$(git status --porcelain)" ]]; then
  echo "[OK] No changes to commit"
  exit 0
fi

echo "[INFO] Auto-committing changes from Copilot session..."

# Stage all changes
git add -A

# Create timestamped commit
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "auto-commit: $TIMESTAMP" --no-verify 2>/dev/null || {
  echo "[WARN] Commit failed"
  exit 0
}

# Attempt to push
if git push 2>/dev/null; then
  echo "[OK] Changes committed and pushed successfully"
else
  echo "[WARN] Push failed - changes committed locally"
fi

exit 0
