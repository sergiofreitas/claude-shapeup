#!/bin/bash
# run-behavioral.sh — Behavioral test runner for Shape Up skills
#
# Usage:
#   ./tests/behavioral/run-behavioral.sh [scenario-name]
#   ./tests/behavioral/run-behavioral.sh --all
#
# Requires: claude CLI with -p (print/headless) mode
#
# Pipeline: scenario → skill prompt + user input → claude -p → judge → verdict

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
CRITERIA_DIR="$SCRIPT_DIR/criteria"
JUDGE_RUBRIC="$SCRIPT_DIR/judge-rubric.md"
RESULTS_DIR="$SCRIPT_DIR/results"
SKILLS_DIR="$PROJECT_ROOT/skills"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

mkdir -p "$RESULTS_DIR"

# Check for claude CLI
if ! command -v claude &> /dev/null; then
  echo -e "${RED}Error: claude CLI not found. Install Claude Code to run behavioral tests.${NC}"
  echo "Behavioral tests require 'claude -p' (headless mode) to generate and judge responses."
  exit 1
fi

usage() {
  echo "Usage:"
  echo "  $0 <scenario-name>     Run a single scenario"
  echo "  $0 --all               Run all scenarios"
  echo "  $0 --list              List available scenarios"
  echo ""
  echo "Available scenarios:"
  for f in "$SCENARIOS_DIR"/*.md; do
    [ -f "$f" ] && echo "  - $(basename "$f" .md)"
  done
}

# Parse a scenario file into components
parse_scenario() {
  local scenario_file="$1"
  local content
  content=$(cat "$scenario_file")

  # Extract sections using sed (macOS-compatible)
  # Each section starts with "## Title" and ends before the next "## "
  SCENARIO_SETUP=$(echo "$content" | sed -n '/^## Setup$/,/^## /p' | sed '1d;$d')
  SCENARIO_PACKAGE=$(echo "$content" | sed -n '/^## Package Context$/,/^## /p' | sed '1d;$d')
  SCENARIO_USER_INPUT=$(echo "$content" | sed -n '/^## User Input$/,/^## /p' | sed '1d;$d' | sed 's/^"//;s/"$//')
  SCENARIO_CRITERIA=$(grep -A1 "^## Criteria" "$scenario_file" | tail -1 | tr -d '[:space:]')
  SCENARIO_EXPECTED=$(echo "$content" | sed -n '/^## Expected Behavior$/,$ p' | sed '1d')
}

# Determine which skill to use based on scenario setup
detect_skill() {
  local setup="$1"
  if echo "$setup" | grep -qi "Builder Agent\|build session"; then
    echo "build"
  elif echo "$setup" | grep -qi "Framing Agent\|framing session"; then
    echo "frame"
  elif echo "$setup" | grep -qi "Shaping Agent\|shaping session"; then
    echo "shape"
  elif echo "$setup" | grep -qi "Ship Agent\|ship session"; then
    echo "ship"
  else
    echo "build"
  fi
}

run_scenario() {
  local scenario_name="$1"
  local scenario_file="$SCENARIOS_DIR/${scenario_name}.md"
  local result_file="$RESULTS_DIR/${scenario_name}.json"

  if [ ! -f "$scenario_file" ]; then
    echo -e "${RED}Scenario not found: $scenario_name${NC}"
    return 1
  fi

  echo -e "${BOLD}--- Scenario: $scenario_name ---${NC}"

  # Parse scenario
  parse_scenario "$scenario_file"

  local skill
  skill=$(detect_skill "$SCENARIO_SETUP")
  local skill_prompt="$SKILLS_DIR/$skill/SKILL.md"

  if [ ! -f "$skill_prompt" ]; then
    echo -e "${RED}Skill prompt not found: $skill_prompt${NC}"
    return 1
  fi

  # Load criteria
  local criteria_file="$CRITERIA_DIR/${SCENARIO_CRITERIA}.md"
  if [ ! -f "$criteria_file" ]; then
    echo -e "${RED}Criteria not found: $criteria_file${NC}"
    return 1
  fi

  echo "  Skill: $skill"
  echo "  Criteria: $SCENARIO_CRITERIA"
  echo "  Generating agent response..."

  # Step 1: Generate agent response using the skill prompt
  local agent_prompt
  agent_prompt=$(cat <<PROMPT
$SCENARIO_SETUP

$SCENARIO_PACKAGE

The user says: $SCENARIO_USER_INPUT

Respond as the agent would. Do NOT write actual code or create files.
Describe what you would do, what scope tasks you would create, and what
you would say to the user. Be specific about your actions.
PROMPT
)

  local agent_response
  agent_response=$(echo "$agent_prompt" | claude -p \
    --append-system-prompt "$(cat "$skill_prompt")" \
    2>/dev/null) || {
    echo -e "${RED}  Failed to generate agent response${NC}"
    return 1
  }

  echo "  Agent responded ($(echo "$agent_response" | wc -w | tr -d ' ') words)"
  echo "  Judging against criteria..."

  # Step 2: Judge the response against criteria
  local judge_input
  judge_input=$(cat <<JUDGE
=== SCENARIO ===
$(cat "$scenario_file")

=== CRITERIA ===
$(cat "$criteria_file")

=== AGENT RESPONSE ===
$agent_response
JUDGE
)

  local verdict
  verdict=$(echo "$judge_input" | claude -p \
    --append-system-prompt "$(cat "$JUDGE_RUBRIC")" \
    2>/dev/null) || {
    echo -e "${RED}  Failed to get judge verdict${NC}"
    return 1
  }

  # Save full results
  cat > "$result_file" <<RESULT
{
  "scenario": "$scenario_name",
  "skill": "$skill",
  "criteria": "$SCENARIO_CRITERIA",
  "agent_response": $(echo "$agent_response" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "\"(encoding error)\""),
  "judge_output": $(echo "$verdict" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "\"(encoding error)\"")
}
RESULT

  # Extract verdict
  if echo "$verdict" | grep -qi '"verdict".*"PASS"'; then
    echo -e "  ${GREEN}PASS${NC}"
    return 0
  elif echo "$verdict" | grep -qi '"verdict".*"FAIL"'; then
    local reason
    reason=$(echo "$verdict" | python3 -c "
import sys, json, re
text = sys.stdin.read()
match = re.search(r'\"reason\"\s*:\s*\"([^\"]+)\"', text)
if match: print(match.group(1))
else: print('(no reason extracted)')
" 2>/dev/null || echo "(parse error)")
    echo -e "  ${RED}FAIL${NC}: $reason"
    return 1
  else
    echo -e "  ${YELLOW}INCONCLUSIVE${NC}: Could not parse judge verdict"
    echo "  Full verdict saved to: $result_file"
    return 1
  fi
}

# --- Main ---

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  --all)
    total=0
    passed=0
    failed=0
    echo -e "${BOLD}=== Behavioral Tests ===${NC}"
    echo ""
    for scenario_file in "$SCENARIOS_DIR"/*.md; do
      [ -f "$scenario_file" ] || continue
      scenario_name=$(basename "$scenario_file" .md)
      total=$((total + 1))
      if run_scenario "$scenario_name"; then
        passed=$((passed + 1))
      else
        failed=$((failed + 1))
      fi
      echo ""
    done
    echo -e "${BOLD}=== Behavioral Results ===${NC}"
    echo -e "  Total:  $total"
    echo -e "  ${GREEN}PASS${NC}:   $passed"
    echo -e "  ${RED}FAIL${NC}:   $failed"
    [ "$failed" -eq 0 ] && echo -e "${GREEN}All behavioral tests passed.${NC}" || echo -e "${RED}$failed test(s) failed.${NC}"
    exit "$failed"
    ;;
  --list)
    echo "Available scenarios:"
    for f in "$SCENARIOS_DIR"/*.md; do
      [ -f "$f" ] && echo "  - $(basename "$f" .md)"
    done
    ;;
  --help|-h)
    usage
    ;;
  *)
    run_scenario "$1"
    ;;
esac
