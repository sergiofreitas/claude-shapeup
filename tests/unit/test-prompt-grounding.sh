#!/bin/bash
# test-prompt-grounding.sh — Unit tests for SKILL.md prompt grounding.
#
# These tests validate audit findings B1 and B2:
#
#   B1: every placeholder the SKILL.md tells the agent to substitute
#       (<plugin-root>, <skill-dir>, <project-root>) must be defined
#       somewhere in that same SKILL.md. If the placeholder appears only
#       as a usage (e.g. `bash <plugin-root>/hooks/lib/...`) and the file
#       never explains what to substitute, the agent has no reliable way
#       to resolve it.
#
#   B2: every `$FEATURE_DIR` reference in the SKILL.md must live in the
#       same markdown bash code block as the `FEATURE_DIR=` assignment
#       that sets it. Claude Code's Bash tool spawns a fresh subprocess
#       per invocation — shell state does NOT persist between calls — so
#       a variable assigned in one ```bash block is empty in the next.
#       (The tool description literally states: "The working directory
#       persists between commands, but shell state does not.")

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

SKILLS=(
  "$PROJECT_ROOT/skills/frame/SKILL.md"
  "$PROJECT_ROOT/skills/shape/SKILL.md"
  "$PROJECT_ROOT/skills/build/SKILL.md"
  "$PROJECT_ROOT/skills/ship/SKILL.md"
)

# --- B1: Placeholder Grounding ----------------------------------------------
#
# A placeholder is considered "defined" if the file contains a line that
# names the placeholder in definition context — i.e. one of:
#   - a markdown table row whose first cell is the placeholder
#   - a list item `- **<placeholder>**: ...`
#   - a prose line mentioning the placeholder next to "is", "means",
#     "refers to", "=", or ":"
#
# A simple, conservative heuristic: grep for any line that contains the
# placeholder AND at least one of those definition markers, AND is NOT
# inside a ```bash ``` code fence (bash usage is not definition).

placeholder_defined() {
  local file="$1"
  local placeholder="$2"
  awk -v ph="$placeholder" '
    /^```/ { in_code = !in_code; next }
    in_code { next }
    index($0, ph) > 0 {
      # Skip lines that look like pure usage (no definition markers).
      if ($0 ~ /(\*\*.*\*\*:[^`])|(: [A-Za-z])|(\<is\>|\<means\>|\<refers\>|=|will resolve|resolves to)/) {
        # Additionally require the placeholder to be a prominent token,
        # not a random path fragment. Accept if it appears in a bullet or
        # table row near the start of the line.
        if ($0 ~ /^[|*-]/ || $0 ~ /^\s*[|*-]/ || $0 ~ /(\*\*.*\*\*:[^`])/) {
          found = 1
        }
      }
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}

echo "=== B1: Placeholder Grounding ==="

PLACEHOLDERS=("<plugin-root>" "<skill-dir>" "<project-root>")

for skill in "${SKILLS[@]}"; do
  name=$(basename "$(dirname "$skill")")
  for ph in "${PLACEHOLDERS[@]}"; do
    # Does the SKILL.md USE the placeholder at all?
    uses=$(grep -c "$ph" "$skill" 2>/dev/null || true)
    [ "$uses" -eq 0 ] && continue

    if placeholder_defined "$skill" "$ph"; then
      pass "[$name] '$ph' is used and defined"
    else
      fail "[$name] '$ph' is used $uses time(s) but never defined"
    fi
  done
done

# --- B2: $FEATURE_DIR Same-Block Assignment ---------------------------------
#
# For every `$FEATURE_DIR` reference in a ```bash ... ``` block inside a
# SKILL.md, require that the SAME bash block contains a `FEATURE_DIR=`
# assignment. Cross-block references fail because Claude's Bash tool
# does not share shell state across invocations.
#
# Prose references outside code fences (e.g. "use the $FEATURE_DIR resolved
# in Step 0") are NOT tested here — those are instructions to the agent,
# not code the agent will execute as-is. The failure mode we're exercising
# is literal bash execution.

block_references_without_assignment() {
  # Stricter: a block fails if it references $FEATURE_DIR before it is
  # assigned within the SAME block. This catches both "no assignment at
  # all" and "assignment comes after first use" (the latter would still
  # break under shell execution because the first use sees an empty
  # variable).
  local file="$1"
  awk '
    BEGIN { in_bash = 0; assigned = 0; bad = ""; block_start = 0 }
    /^```bash$/ {
      in_bash = 1
      assigned = 0
      block_start = NR
      next
    }
    /^```/ && in_bash {
      in_bash = 0
      next
    }
    in_bash {
      ref = ($0 ~ /\$FEATURE_DIR/ || $0 ~ /\$\{FEATURE_DIR[:}]/)
      assn = ($0 ~ /FEATURE_DIR=/)
      if (ref && !assigned) {
        bad = bad block_start "\n"
      }
      if (assn) assigned = 1
    }
    END { printf "%s", bad }
  ' "$file"
}

echo ""
echo "=== B2: \$FEATURE_DIR Same-Block Assignment ==="

for skill in "${SKILLS[@]}"; do
  name=$(basename "$(dirname "$skill")")

  bad_blocks=$(block_references_without_assignment "$skill")
  if [ -z "$bad_blocks" ]; then
    # Only emit a pass if the skill actually uses $FEATURE_DIR at all.
    if grep -q '\$FEATURE_DIR' "$skill" 2>/dev/null; then
      pass "[$name] every bash block that references \$FEATURE_DIR assigns it locally"
    fi
    continue
  fi

  count=$(echo "$bad_blocks" | sed '/^$/d' | wc -l | tr -d ' ')
  fail "[$name] $count bash block(s) reference \$FEATURE_DIR without a local FEATURE_DIR= assignment (block start lines: $(echo "$bad_blocks" | tr '\n' ' '))"
done

# Additional sub-check: prose references require an upstream assignment
# somewhere in the file. If the file references $FEATURE_DIR at all but
# never assigns it anywhere, that is a strict failure.
echo ""
echo "=== B2b: \$FEATURE_DIR assignment exists somewhere in file ==="

for skill in "${SKILLS[@]}"; do
  name=$(basename "$(dirname "$skill")")
  refs=$(grep -c '\$FEATURE_DIR' "$skill" 2>/dev/null || true)
  [ "$refs" -eq 0 ] && continue
  assigns=$(grep -c 'FEATURE_DIR=' "$skill" 2>/dev/null || true)
  if [ "$assigns" -eq 0 ]; then
    fail "[$name] references \$FEATURE_DIR ($refs time(s)) but never assigns FEATURE_DIR= anywhere"
  else
    pass "[$name] \$FEATURE_DIR has $assigns assignment(s) somewhere in the file"
  fi
done

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All prompt-grounding tests passed." || echo "$FAIL test(s) failed."
exit "$FAIL"
