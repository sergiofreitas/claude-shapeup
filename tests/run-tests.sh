#!/bin/bash
# run-tests.sh — Shape Up Build Skill Dry-Run Test Runner
#
# Usage:
#   ./tests/run-tests.sh <fixture-name> [--structural-only]
#   ./tests/run-tests.sh --baseline <shipped-project-path> [<package-path>]
#   ./tests/run-tests.sh --all
#
# Modes:
#   <fixture-name>          Run dry-run against a fixture, then evaluate
#   --baseline <path>       Run structural checks against an existing shipped project
#   --all                   Run all fixtures sequentially
#
# Options:
#   --structural-only       Skip LLM-as-judge evaluation, run only structural checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
RESULTS_DIR="$SCRIPT_DIR/results"
ASSERTIONS_DIR="$SCRIPT_DIR/assertions"
STRUCTURAL_CHECKS="$ASSERTIONS_DIR/structural-checks.sh"
QUALITY_RUBRIC="$ASSERTIONS_DIR/quality-rubric.md"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
  echo "Usage:"
  echo "  $0 <fixture-name> [--structural-only]"
  echo "  $0 --baseline <shipped-project-path> [<package-path>]"
  echo "  $0 --all"
  echo ""
  echo "Available fixtures:"
  for dir in "$FIXTURES_DIR"/*/; do
    [ -d "$dir" ] && echo "  - $(basename "$dir")"
  done
}

# --- Baseline mode: run structural checks against existing shipped project ---
run_baseline() {
  local project_path="$1"
  local package_path="${2:-}"

  echo -e "${BOLD}=== Baseline Check ===${NC}"
  echo "  Project: $project_path"
  echo ""

  "$STRUCTURAL_CHECKS" "$project_path" "$package_path"
  return $?
}

# --- Fixture mode: dry-run + evaluate ---
run_fixture() {
  local fixture_name="$1"
  local structural_only="${2:-false}"
  local fixture_dir="$FIXTURES_DIR/$fixture_name"
  local result_dir="$RESULTS_DIR/$fixture_name"
  local package_path="$fixture_dir/package.md"

  if [ ! -d "$fixture_dir" ]; then
    echo -e "${RED}Fixture not found: $fixture_name${NC}"
    echo "Available fixtures:"
    for dir in "$FIXTURES_DIR"/*/; do
      [ -d "$dir" ] && echo "  - $(basename "$dir")"
    done
    exit 1
  fi

  echo -e "${BOLD}=== Dry-Run Test: $fixture_name ===${NC}"
  echo ""

  # Step 1: Check if results exist
  if [ ! -d "$result_dir" ]; then
    echo -e "${YELLOW}No results found at: $result_dir${NC}"
    echo ""
    echo "To generate results, run the build skill in dry-run mode:"
    echo ""
    echo "  1. Start a new Claude Code session"
    echo "  2. Provide the fixture package as context:"
    echo "     cat $package_path"
    echo "  3. Use this system prompt addition:"
    echo '     "This is a planning-only dry run. Do NOT write actual code.'
    echo '      Produce only Shape Up build artifacts: orientation.md, scopes/, hillchart.md.'
    echo '      Simulate the scope discovery process as if you were building against a real'
    echo '      codebase, but describe what you WOULD build instead of building it.'
    echo '      Write all artifacts to: '"$result_dir"'"'
    echo ""
    echo "  4. Then re-run this test:"
    echo "     $0 $fixture_name"
    echo ""
    exit 2
  fi

  # Step 2: Run structural checks
  echo -e "${BOLD}--- Phase 1: Structural Checks ---${NC}"
  echo ""

  local struct_exit=0
  "$STRUCTURAL_CHECKS" "$result_dir" "$package_path" || struct_exit=$?

  echo ""

  if [ "$structural_only" = "true" ]; then
    echo -e "${BOLD}=== Structural-only mode — skipping quality evaluation ===${NC}"
    return $struct_exit
  fi

  # Step 3: LLM-as-judge quality evaluation
  echo -e "${BOLD}--- Phase 2: Quality Evaluation (LLM-as-judge) ---${NC}"
  echo ""

  # Collect all artifacts into a single context
  local artifacts_file
  artifacts_file=$(mktemp)

  echo "=== PACKAGE (input) ===" >> "$artifacts_file"
  cat "$package_path" >> "$artifacts_file"
  echo "" >> "$artifacts_file"

  for f in orientation.md hillchart.md; do
    if [ -f "$result_dir/$f" ]; then
      echo "=== $f ===" >> "$artifacts_file"
      cat "$result_dir/$f" >> "$artifacts_file"
      echo "" >> "$artifacts_file"
    fi
  done

  if [ -d "$result_dir/scopes" ]; then
    for f in "$result_dir"/scopes/*.md; do
      [ -f "$f" ] || continue
      local fname
      fname=$(basename "$f")
      echo "=== scopes/$fname ===" >> "$artifacts_file"
      cat "$f" >> "$artifacts_file"
      echo "" >> "$artifacts_file"
    done
  fi

  for f in "$result_dir"/handover-*.md; do
    [ -f "$f" ] || continue
    local fname
    fname=$(basename "$f")
    echo "=== $fname ===" >> "$artifacts_file"
    cat "$f" >> "$artifacts_file"
    echo "" >> "$artifacts_file"
  done

  echo ""
  echo "Artifacts collected. To run the quality evaluation:"
  echo ""
  echo "  1. Feed the rubric and artifacts to Claude:"
  echo "     cat $QUALITY_RUBRIC $artifacts_file"
  echo ""
  echo "  2. Or use the Claude CLI:"
  echo "     cat $artifacts_file | claude --print -s \"\$(cat $QUALITY_RUBRIC)\""
  echo ""
  echo "  Artifacts file: $artifacts_file"
  echo ""

  rm -f "$artifacts_file" 2>/dev/null || true

  return $struct_exit
}

# --- Parse arguments ---

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  --baseline)
    shift
    run_baseline "$@"
    ;;
  --all)
    total_failures=0
    for dir in "$FIXTURES_DIR"/*/; do
      [ -d "$dir" ] || continue
      fixture=$(basename "$dir")
      run_fixture "$fixture" "true" || total_failures=$((total_failures + $?))
      echo ""
      echo "---"
      echo ""
    done
    echo -e "${BOLD}=== All Fixtures Complete ===${NC}"
    if [ "$total_failures" -eq 0 ]; then
      echo -e "${GREEN}All passed.${NC}"
    else
      echo -e "${RED}Total failures across all fixtures: $total_failures${NC}"
    fi
    exit "$total_failures"
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    fixture_name="$1"
    structural_only="false"
    [ "${2:-}" = "--structural-only" ] && structural_only="true"
    run_fixture "$fixture_name" "$structural_only"
    ;;
esac
