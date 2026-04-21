#!/bin/bash
# run-all.sh — Two-layer test suite for the Shape Up plugin
#
# Usage:
#   ./tests/run-all.sh                Run unit + behavioral
#   ./tests/run-all.sh --unit         Deterministic tests only (no LLM, seconds)
#   ./tests/run-all.sh --behavioral   Criteria-based behavioral tests (LLM-as-judge, slow)
#
# Design:
#   - Unit tests cover scaffolding (hooks, scripts, prompt structure) where exact
#     outputs are verifiable. Fast, deterministic, runs on every commit.
#   - Behavioral tests cover outcomes (what the agent actually does when a SKILL
#     is applied) via an LLM judge against rubric-based criteria. Slow and
#     non-deterministic — runs on pre-push / in CI, not on every commit.
#
# There is no snapshot/baseline layer: exact-text diffs against a non-deterministic
# generator is a category error. Regressions on meaning belong in the behavioral
# layer; regressions on scaffolding belong in the unit layer.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

RUN_UNIT=false
RUN_BEHAVIORAL=false
EXPLICIT_SELECTION=false

for arg in "$@"; do
  case "$arg" in
    --unit)        RUN_UNIT=true; EXPLICIT_SELECTION=true ;;
    --behavioral)  RUN_BEHAVIORAL=true; EXPLICIT_SELECTION=true ;;
    --help|-h)
      echo "Usage: $0 [--unit] [--behavioral]"
      echo ""
      echo "Layers:"
      echo "  --unit          Hooks, scripts, prompt structure (no LLM, seconds)"
      echo "  --behavioral    Agent outcomes via LLM-as-judge (needs claude CLI)"
      echo ""
      echo "Default: run both layers"
      exit 0
      ;;
  esac
done

if [ "$EXPLICIT_SELECTION" = false ]; then
  RUN_UNIT=true
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
# Layer 1: Unit Tests (deterministic, no LLM)
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
    if [ "$RUN_BEHAVIORAL" = true ]; then
      echo "Skipping behavioral layer."
      RUN_BEHAVIORAL=false
    fi
  else
    echo -e "${GREEN}All unit tests passed.${NC}"
  fi
  echo ""
fi

# ─────────────────────────────────────────
# Layer 2: Behavioral Tests (LLM-as-judge)
# ─────────────────────────────────────────
if [ "$RUN_BEHAVIORAL" = true ]; then
  LAYERS_RUN=$((LAYERS_RUN + 1))
  echo -e "${BOLD}━━━ Layer 2: Behavioral Tests (LLM-as-judge) ━━━${NC}"
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
