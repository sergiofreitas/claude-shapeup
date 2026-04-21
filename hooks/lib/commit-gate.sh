#!/bin/bash
# commit-gate.sh — Pre-commit consistency gate for .shapeup/ tracking docs.
#
# Usage: commit-gate.sh <project-root>
#
# Inspects the staged diff for files under `.shapeup/<feature>/` and runs
# `check-consistency.sh <feature-dir> audit` on each touched feature folder.
# If any FAIL or WARN surfaces, prints the findings and exits non-zero — the
# scope/hillchart/must-have state disagrees and the commit should be fixed,
# not pushed through.
#
# Exits:
#   0 — no .shapeup/ files staged, or every touched feature audits clean
#   1 — at least one feature folder has FAIL/WARN drift
#   2 — usage error (no project root, gate mis-invoked)
#
# Read-only: the only git command invoked is `git diff --cached --name-only`.

set -u

PROJECT_ROOT="${1:-}"
if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT" ]; then
  echo "commit-gate: project root not found: ${PROJECT_ROOT:-<empty>}" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$SCRIPT_DIR/check-consistency.sh"

if [ ! -f "$CHECKER" ]; then
  echo "commit-gate: check-consistency.sh missing at $CHECKER" >&2
  exit 2
fi

cd "$PROJECT_ROOT" || exit 2

# Not a git repo? Nothing to gate.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null || true)
FEATURE_DIRS=$(echo "$STAGED" \
  | grep -E '^\.shapeup/[^/]+/' \
  | sed -E 's|^(\.shapeup/[^/]+)/.*|\1|' \
  | sort -u)

if [ -z "$FEATURE_DIRS" ]; then
  exit 0
fi

FAILED=0
REPORT=""

while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  full="$PROJECT_ROOT/$rel"
  [ -d "$full" ] || continue
  out=$(bash "$CHECKER" "$full" audit 2>&1)
  findings=$(echo "$out" | grep -E '^(FAIL|WARN):' || true)
  if [ -n "$findings" ]; then
    FAILED=1
    REPORT="${REPORT}"$'\n--- '"$rel"$' ---\n'"$findings"$'\n'
  fi
done <<< "$FEATURE_DIRS"

if [ "$FAILED" = "1" ]; then
  cat >&2 <<EOF
commit-gate: .shapeup/ tracking docs disagree with the staged diff.

Each scope-completion commit must bundle code + the scope file + hillchart.md
so the next session starts from a coherent state. Fix the findings below,
re-stage, and try again.
$REPORT
Typical fixes:
  - Scope claims ✓ Done but has unchecked must-haves → tick the boxes, cut with ~,
    or revert the hill position.
  - hillchart.md lists a scope that has no scope-*.md file → remove the entry
    or add the missing scope file.
  - Scope file exists but not in hillchart.md → add it with its current symbol.

Do NOT bypass with --no-verify unless the drift is genuinely irrelevant to
what you're committing (and document why).
EOF
  exit 1
fi

exit 0
