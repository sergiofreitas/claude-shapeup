#!/bin/bash
# test-validate-package.sh — Unit tests for package validation, including cost tracking.

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATOR="$PROJECT_ROOT/skills/shape/scripts/validate-package.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

write_package() {
  local path="$1"
  local cost_block="$2"
  cat > "$path" <<EOF
# Package: Test

**Appetite**: Small Batch (1 session)

## Problem
A specific problem.

$cost_block

## Requirements
- **R0**: User can do the thing

## Solution
Use the existing path.

### Changes
| File / Module | Change | Serves |
|---------------|--------|--------|
| src/example.ts | Add behavior | R0 |

**Fit check**: Every R above maps to at least one change. No gaps.

## Rabbit Holes
- **Risk**: Resolved.

## No-Gos
- **Extra mode**: Out of appetite.

## Technical Validation
**Key files reviewed**: src/example.ts
**Approach validated**: Existing pattern works.
**Test strategy**: TDD.
EOF
}

echo "=== validate-package: Cost Tracking (USD) ==="

VALID="$TMPDIR/valid.md"
write_package "$VALID" '## Cost Tracking (USD)

| Metric | Amount | Source / Notes |
|--------|--------|----------------|
| Estimated | $120 | 3 AI sessions at $40/session |
| Actual | Pending build | Fill later |'
if bash "$VALIDATOR" "$VALID" >/tmp/validate-package-valid.log 2>&1; then
  pass "passes with estimated USD cost"
else
  fail "should pass with estimated USD cost"
  cat /tmp/validate-package-valid.log
fi

MISSING="$TMPDIR/missing.md"
write_package "$MISSING" ''
if bash "$VALIDATOR" "$MISSING" >/tmp/validate-package-missing.log 2>&1; then
  fail "should fail without Cost Tracking section"
else
  if grep -q 'MISSING SECTION: ## Cost Tracking (USD)' /tmp/validate-package-missing.log; then
    pass "fails without Cost Tracking section"
  else
    fail "missing Cost Tracking failure was not reported"
    cat /tmp/validate-package-missing.log
  fi
fi

UNKNOWN="$TMPDIR/unknown.md"
write_package "$UNKNOWN" '## Cost Tracking (USD)

| Metric | Amount | Source / Notes |
|--------|--------|----------------|
| Estimated | Unknown | No billing basis available during shaping |
| Actual | Pending build | Fill later |'
if bash "$VALIDATOR" "$UNKNOWN" >/tmp/validate-package-unknown.log 2>&1; then
  pass "allows explicit Unknown estimate with notes"
else
  fail "should allow explicit Unknown estimate with notes"
  cat /tmp/validate-package-unknown.log
fi

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All validate-package tests passed." || echo "$FAIL test(s) failed."
exit "$FAIL"
