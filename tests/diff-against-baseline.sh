#!/bin/bash
# diff-against-baseline.sh — Regression gate for prompt changes.
#
# Regenerates artifacts for each fixture into a scratch directory, then diffs
# against the committed tests/results/ baselines. Unexpected diffs mean a
# prompt change has shifted the generated output — the reviewer must decide
# whether that drift was intentional.
#
# Exit codes:
#   0  no drift (or --update succeeded)
#   1  drift detected (diffs emitted to stderr)
#   2  generation failed for at least one fixture
#
# Usage:
#   ./tests/diff-against-baseline.sh                     diff all fixtures
#   ./tests/diff-against-baseline.sh <fixture-name>      diff one fixture
#   ./tests/diff-against-baseline.sh --update            regenerate and overwrite baselines
#   ./tests/diff-against-baseline.sh --update <name>     regenerate one baseline
#
# Typical workflow — see CONTRIBUTING.md § "Prompt-change workflow" for the full rundown:
#   1. Edit a SKILL.md.
#   2. Run this script without flags. Review any drift.
#   3. If drift is intentional: rerun with --update, then commit the updated baselines
#      alongside your prompt changes.
#   4. If drift is unintentional: fix the prompt until diffs go away.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
BASELINE_DIR="$SCRIPT_DIR/results"
GENERATOR="$SCRIPT_DIR/generate-artifacts.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

MODE="diff"
FIXTURE=""

for arg in "$@"; do
  case "$arg" in
    --update)       MODE="update" ;;
    --help|-h)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    --*)
      echo "Unknown flag: $arg" >&2
      exit 2
      ;;
    *)
      FIXTURE="$arg"
      ;;
  esac
done

if ! command -v claude >/dev/null 2>&1; then
  echo -e "${RED}Error: claude CLI not found. Install Claude Code to regenerate artifacts.${NC}" >&2
  exit 2
fi

if [ ! -x "$GENERATOR" ]; then
  echo -e "${RED}Error: generator not executable at $GENERATOR${NC}" >&2
  exit 2
fi

collect_fixtures() {
  if [ -n "$FIXTURE" ]; then
    echo "$FIXTURE"
    return
  fi
  for dir in "$FIXTURES_DIR"/*/; do
    [ -d "$dir" ] || continue
    basename "$dir"
  done
}

diff_fixture() {
  local name="$1"
  local scratch="$2"
  local baseline="$BASELINE_DIR/$name"
  local generated="$scratch/$name"

  if [ ! -d "$generated" ]; then
    echo -e "${RED}[$name] generation produced no output${NC}" >&2
    return 2
  fi

  if [ ! -d "$baseline" ]; then
    echo -e "${YELLOW}[$name] no baseline exists yet — treat every file as drift${NC}"
    diff -ruN /dev/null "$generated"
    return 1
  fi

  # Ignore whitespace-only diffs (LLM output often reflows). Keep semantic diffs.
  local diff_output
  diff_output=$(diff -ruN --ignore-all-space "$baseline" "$generated" 2>&1)
  if [ -z "$diff_output" ]; then
    echo -e "${GREEN}[$name] no drift${NC}"
    return 0
  fi

  echo -e "${YELLOW}[$name] drift detected:${NC}" >&2
  echo "$diff_output" >&2
  return 1
}

update_fixture() {
  local name="$1"
  local scratch="$2"
  local generated="$scratch/$name"

  if [ ! -d "$generated" ]; then
    echo -e "${RED}[$name] generation produced no output — baseline left unchanged${NC}" >&2
    return 2
  fi

  rm -rf "$BASELINE_DIR/$name"
  mkdir -p "$BASELINE_DIR"
  cp -R "$generated" "$BASELINE_DIR/$name"
  echo -e "${GREEN}[$name] baseline updated${NC}"
  return 0
}

main() {
  local fixtures
  fixtures=$(collect_fixtures)
  if [ -z "$fixtures" ]; then
    echo -e "${RED}No fixtures found under $FIXTURES_DIR${NC}" >&2
    exit 2
  fi

  local scratch
  scratch=$(mktemp -d -t shapeup-baseline-XXXXXX)
  trap 'rm -rf "$scratch"' EXIT

  local drift=0
  local gen_failed=0

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    echo -e "${BOLD}--- $name ---${NC}"

    # Regenerate into scratch
    if ! GENERATE_RESULTS_DIR="$scratch" "$GENERATOR" "$name" >/dev/null 2>&1; then
      echo -e "${RED}[$name] generation failed${NC}" >&2
      gen_failed=1
      continue
    fi

    if [ "$MODE" = "update" ]; then
      update_fixture "$name" "$scratch" || gen_failed=1
    else
      case "$(diff_fixture "$name" "$scratch"; echo $?)" in
        *1) drift=1 ;;
        *2) gen_failed=1 ;;
      esac
    fi
  done <<< "$fixtures"

  echo ""
  echo -e "${BOLD}=== Summary ===${NC}"
  if [ "$gen_failed" -ne 0 ]; then
    echo -e "${RED}One or more fixtures failed to generate.${NC}"
    exit 2
  fi
  if [ "$MODE" = "update" ]; then
    echo -e "${GREEN}Baselines updated. Review the diff in git and commit.${NC}"
    exit 0
  fi
  if [ "$drift" -ne 0 ]; then
    echo -e "${YELLOW}Drift detected. Review the diffs above. If intentional, rerun with --update.${NC}"
    exit 1
  fi
  echo -e "${GREEN}All fixtures match their baselines.${NC}"
  exit 0
}

main
