#!/bin/bash
# generate-artifacts.sh — Generate build artifacts from fixtures using claude -p
#
# This is the missing generation step that unblocks the existing test harness.
# Pipeline: fixture (package.md) → claude -p with build skill → artifacts in results/
#
# Usage:
#   ./tests/generate-artifacts.sh <fixture-name>
#   ./tests/generate-artifacts.sh --all
#
# After generation, run structural checks:
#   ./tests/run-tests.sh <fixture-name> --structural-only

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
RESULTS_DIR="$SCRIPT_DIR/results"
BUILD_SKILL="$PROJECT_ROOT/skills/build/SKILL.md"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

if ! command -v claude &> /dev/null; then
  echo -e "${RED}Error: claude CLI not found. Install Claude Code to generate artifacts.${NC}"
  exit 1
fi

usage() {
  echo "Usage:"
  echo "  $0 <fixture-name>    Generate artifacts for one fixture"
  echo "  $0 --all             Generate artifacts for all fixtures"
  echo "  $0 --list            List available fixtures"
  echo ""
  echo "Available fixtures:"
  for dir in "$FIXTURES_DIR"/*/; do
    [ -d "$dir" ] && echo "  - $(basename "$dir")"
  done
}

generate_fixture() {
  local fixture_name="$1"
  local fixture_dir="$FIXTURES_DIR/$fixture_name"
  local result_dir="$RESULTS_DIR/$fixture_name"
  local package_path="$fixture_dir/package.md"

  if [ ! -d "$fixture_dir" ]; then
    echo -e "${RED}Fixture not found: $fixture_name${NC}"
    return 1
  fi

  if [ ! -f "$package_path" ]; then
    echo -e "${RED}Package not found: $package_path${NC}"
    return 1
  fi

  echo -e "${BOLD}=== Generating: $fixture_name ===${NC}"

  # Check for handover (continuation scenario)
  local handover_context=""
  if [ -f "$fixture_dir/handover-01.md" ]; then
    handover_context="

=== HANDOVER FROM PREVIOUS SESSION ===
$(cat "$fixture_dir/handover-01.md")"
  fi

  # Build the generation prompt
  local gen_prompt
  gen_prompt=$(cat <<GENPROMPT
This is a planning-only dry run of the Build skill. Do NOT write actual code.

You are given a shaped Package with Shape Go approval. Simulate the build process
and produce ONLY these Shape Up build artifacts:

1. orientation.md — Your orientation analysis:
   - Problem Restated (in your own words, not copy-pasted)
   - Codebase Observations (what you'd expect to find)
   - Imagined vs. Discovered (tensions between package and reality)
   - First Piece Selection (with Core/Small/Novel reasoning)

2. scopes/ directory with:
   - scopes/unscoped.md — tasks that don't fit a scope yet
   - scopes/scope-<name>.md for each discovered scope, containing:
     - Hill Position (▲/▼/✓)
     - Prioritization Reasoning (risk, dependencies, WHY this order)
     - Must-Haves (task list)
     - Nice-to-Haves (~) if any
     - Notes

3. hillchart.md — Hill chart with:
   - Scopes section (positions)
   - Sequencing Rationale (inverted pyramid reasoning)
   - Risk (riskiest scope)
   - Next (what to push uphill)
   - History section with at least one "### Session" entry showing movement

IMPORTANT scope rules:
- Scope names must describe a BUSINESS CAPABILITY, not a technical layer
- Each scope must deliver end-to-end verifiable functionality
- Do NOT name scopes "backend-X", "frontend-X", "database-X"
- Scopes must differ from Package element names

=== PACKAGE ===
$(cat "$package_path")
$handover_context

Write each artifact as a separate section with clear delimiters:
--- FILE: orientation.md ---
(content)
--- FILE: scopes/unscoped.md ---
(content)
--- FILE: scopes/scope-<name>.md ---
(content)
--- FILE: hillchart.md ---
(content)
GENPROMPT
)

  # Generate via claude -p
  echo "  Running claude -p (this may take 30-60 seconds)..."
  local output
  output=$(echo "$gen_prompt" | claude -p \
    --append-system-prompt "$(cat "$BUILD_SKILL")" \
    2>/dev/null) || {
    echo -e "${RED}  Generation failed${NC}"
    return 1
  }

  # Parse output into files
  echo "  Parsing artifacts..."
  rm -rf "$result_dir"
  mkdir -p "$result_dir/scopes"

  # Extract each file section
  echo "$output" | awk '
    /^--- FILE: / {
      if (outfile) close(outfile)
      fname = $0
      sub(/^--- FILE: /, "", fname)
      sub(/ ---$/, "", fname)
      outfile = "'"$result_dir"'/" fname
      # Ensure directory exists
      dir = outfile
      sub(/\/[^\/]+$/, "", dir)
      system("mkdir -p \"" dir "\"")
      next
    }
    outfile { print > outfile }
  '

  # Verify artifacts were created
  local artifact_count=0
  [ -f "$result_dir/orientation.md" ] && artifact_count=$((artifact_count + 1))
  [ -f "$result_dir/hillchart.md" ] && artifact_count=$((artifact_count + 1))
  [ -d "$result_dir/scopes" ] && artifact_count=$((artifact_count + $(ls "$result_dir"/scopes/*.md 2>/dev/null | wc -l | tr -d ' ')))

  if [ "$artifact_count" -eq 0 ]; then
    echo -e "${YELLOW}  Warning: No artifacts parsed from output. Saving raw output.${NC}"
    echo "$output" > "$result_dir/raw-output.md"
    echo "  Raw output saved to: $result_dir/raw-output.md"
    echo "  You may need to manually split this into artifact files."
    return 1
  fi

  echo -e "  ${GREEN}Generated $artifact_count artifact files${NC}"
  echo "  Results in: $result_dir/"
  ls -1 "$result_dir/"
  [ -d "$result_dir/scopes" ] && echo "  scopes/:" && ls -1 "$result_dir/scopes/"
  return 0
}

# --- Main ---

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  --all)
    total=0
    success=0
    for dir in "$FIXTURES_DIR"/*/; do
      [ -d "$dir" ] || continue
      fixture=$(basename "$dir")
      total=$((total + 1))
      if generate_fixture "$fixture"; then
        success=$((success + 1))
      fi
      echo ""
    done
    echo -e "${BOLD}=== Generation Complete ===${NC}"
    echo "  Generated: $success / $total fixtures"
    [ "$success" -eq "$total" ] && exit 0 || exit 1
    ;;
  --list)
    echo "Available fixtures:"
    for dir in "$FIXTURES_DIR"/*/; do
      [ -d "$dir" ] && echo "  - $(basename "$dir")"
    done
    ;;
  --help|-h)
    usage
    ;;
  *)
    generate_fixture "$1"
    ;;
esac
