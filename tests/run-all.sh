#!/bin/bash
# run-all.sh — Complete test suite for the Shape Up plugin
#
# Usage:
#   ./tests/run-all.sh                Run all tests (unit + structural + behavioral)
#   ./tests/run-all.sh --unit         Run only unit tests (no LLM, fast)
#   ./tests/run-all.sh --structural   Generate artifacts + run structural checks
#   ./tests/run-all.sh --behavioral   Run only behavioral tests
#   ./tests/run-all.sh --no-generate  Skip artifact generation (use existing results/)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

RUN_UNIT=false
RUN_STRUCTURAL=false
RUN_BEHAVIORAL=false
SKIP_GENERATE=false
EXPLICIT_SELECTION=false

# Parse args
for arg in "$@"; do
  case "$arg" in
    --unit)        RUN_UNIT=true; EXPLICIT_SELECTION=true ;;
    --structural)  RUN_STRUCTURAL=true; EXPLICIT_SELECTION=true ;;
    --behavioral)  RUN_BEHAVIORAL=true; EXPLICIT_SELECTION=true ;;
    --no-generate) SKIP_GENERATE=true ;;
    --help|-h)
      echo "Usage: $0 [--unit] [--structural] [--behavioral] [--no-generate]"
      echo ""
      echo "Layers:"
      echo "  --unit          Hooks and scripts (no LLM, seconds)"
      echo "  --structural    Artifact generation + structural checks (needs claude CLI)"
      echo "  --behavioral    Criteria-based behavioral tests (needs claude CLI)"
      echo "  --no-generate   Skip artifact generation, use existing results/"
      echo ""
      echo "Default: run all layers"
      exit 0
      ;;
  esac
done

# If no explicit selection, run all layers
if [ "$EXPLICIT_SELECTION" = false ]; then
  RUN_UNIT=true
  RUN_STRUCTURAL=true
  RUN_BEHAVIORAL=true
fi

TOTAL_PASS=0
TOTAL_FAIL=0
LAYERS_RUN=0

echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Shape Up Plugin — Test Suite           ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ─────────────────────────────────────────
# Layer 1: Unit Tests (no LLM)
# ─────────────────────────────────────────
if [ "$RUN_UNIT" = true ]; then
  LAYERS_RUN=$((LAYERS_RUN + 1))
  echo -e "${BOLD}━━━ Layer 1: Unit Tests (deterministic) ━━━${NC}"
  echo ""

  unit_fail=0
  for test_file in "$SCRIPT_DIR"/unit/test-*.sh; do
    [ -f "$test_file" ] || continue
    test_name=$(basename "$test_file" .sh)
    echo -e "${BOLD}$test_name${NC}"
    if bash "$test_file"; then
      TOTAL_PASS=$((TOTAL_PASS + 1))
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
      unit_fail=$((unit_fail + 1))
    fi
    echo ""
  done

  if [ "$unit_fail" -gt 0 ]; then
    echo -e "${RED}Unit tests failed. Fix before running LLM tests.${NC}"
    if [ "$RUN_STRUCTURAL" = true ] || [ "$RUN_BEHAVIORAL" = true ]; then
      echo "Skipping remaining layers."
      RUN_STRUCTURAL=false
      RUN_BEHAVIORAL=false
    fi
  else
    echo -e "${GREEN}All unit tests passed.${NC}"
  fi
  echo ""
fi

# ─────────────────────────────────────────
# Layer 2: Structural Tests (artifact generation + checks)
# ─────────────────────────────────────────
if [ "$RUN_STRUCTURAL" = true ]; then
  LAYERS_RUN=$((LAYERS_RUN + 1))
  echo -e "${BOLD}━━━ Layer 2: Structural Tests ━━━${NC}"
  echo ""

  if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Skipping: claude CLI not found (needed for artifact generation)${NC}"
    echo "Install Claude Code or run with --unit for deterministic tests only."
  else
    # Generate artifacts if needed
    if [ "$SKIP_GENERATE" = false ]; then
      echo "Generating artifacts from fixtures..."
      echo ""
      bash "$SCRIPT_DIR/generate-artifacts.sh" --all
      echo ""
    fi

    # Run structural checks on generated artifacts
    echo "Running structural checks..."
    echo ""
    if bash "$SCRIPT_DIR/run-tests.sh" --all; then
      TOTAL_PASS=$((TOTAL_PASS + 1))
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
  fi
  echo ""
fi

# ─────────────────────────────────────────
# Layer 3: Behavioral Tests (LLM-as-judge)
# ─────────────────────────────────────────
if [ "$RUN_BEHAVIORAL" = true ]; then
  LAYERS_RUN=$((LAYERS_RUN + 1))
  echo -e "${BOLD}━━━ Layer 3: Behavioral Tests ━━━${NC}"
  echo ""

  if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Skipping: claude CLI not found (needed for behavioral tests)${NC}"
  else
    if bash "$SCRIPT_DIR/behavioral/run-behavioral.sh" --all; then
      TOTAL_PASS=$((TOTAL_PASS + 1))
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
  fi
  echo ""
fi

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Test Suite Summary                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Layers run: $LAYERS_RUN"
echo -e "  ${GREEN}PASS${NC}: $TOTAL_PASS"
echo -e "  ${RED}FAIL${NC}: $TOTAL_FAIL"
echo ""

if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo -e "${GREEN}All tests passed.${NC}"
  exit 0
else
  echo -e "${RED}$TOTAL_FAIL layer(s) failed.${NC}"
  exit 1
fi
