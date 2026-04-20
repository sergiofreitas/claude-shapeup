#!/bin/bash
# setup-hooks.sh — point this clone's git at the tracked .githooks/ directory.
#
# Run once per clone. Idempotent.
#
# Why: .git/hooks/ is not tracked by git, so per-clone hook setup would
# otherwise require copying files after every pull. Setting core.hooksPath
# makes git read hooks directly from the tracked .githooks/ directory,
# so updates to the hooks arrive via normal git pulls with no extra step.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.githooks"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "setup-hooks.sh: $HOOKS_DIR not found — are you in the right repo?" >&2
  exit 1
fi

# Ensure hooks are executable (git requires this even with core.hooksPath).
for hook in "$HOOKS_DIR"/*; do
  [ -f "$hook" ] && chmod +x "$hook"
done

git -C "$REPO_ROOT" config core.hooksPath .githooks

echo "Git hooks activated. core.hooksPath = .githooks"
echo ""
echo "Installed hooks:"
ls -1 "$HOOKS_DIR"
echo ""
echo "To bypass any hook on a specific commit: git commit --no-verify"
echo "Only do this when you know exactly why — see CLAUDE.md for the workflow."
