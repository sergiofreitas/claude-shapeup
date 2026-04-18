#!/bin/bash
# test-ripple-check.sh — Unit tests for hooks/ripple-check.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RIPPLE="$PROJECT_ROOT/hooks/ripple-check.sh"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

run_ripple() {
  local file_path="$1"
  echo "{\"tool_input\": {\"file_path\": \"$file_path\"}}" | bash "$RIPPLE" 2>&1
}

echo "=== Ripple Check: scope naming advisory ==="

# Horizontal scope names should trigger warning
OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-backend-api.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  pass "detects 'backend-api' as horizontal"
else
  fail "should detect 'backend-api' as horizontal"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-frontend-ui.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  pass "detects 'frontend-ui' as horizontal"
else
  fail "should detect 'frontend-ui' as horizontal"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-database-migrations.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  pass "detects 'database-migrations' as horizontal"
else
  fail "should detect 'database-migrations' as horizontal"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-migrations.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  pass "detects 'migrations' as horizontal"
else
  fail "should detect 'migrations' as horizontal"
fi

# Good scope names should NOT trigger warning
OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-invoice-filtering.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  fail "should not flag 'invoice-filtering' as horizontal"
else
  pass "'invoice-filtering' not flagged"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-user-can-export-grades.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  fail "should not flag 'user-can-export-grades' as horizontal"
else
  pass "'user-can-export-grades' not flagged"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/scopes/scope-notification-preferences.md")
if echo "$OUTPUT" | grep -q "SCOPE NAMING"; then
  fail "should not flag 'notification-preferences' as horizontal"
else
  pass "'notification-preferences' not flagged"
fi

echo ""
echo "=== Ripple Check: document type detection ==="

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/frame.md")
if echo "$OUTPUT" | grep -q "RIPPLE CHECK — frame.md"; then
  pass "detects frame.md modification"
else
  fail "should detect frame.md"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/package.md")
if echo "$OUTPUT" | grep -q "RIPPLE CHECK — package.md"; then
  pass "detects package.md modification"
else
  fail "should detect package.md"
fi

OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/hillchart.md")
if echo "$OUTPUT" | grep -q "RIPPLE CHECK — hillchart.md"; then
  pass "detects hillchart.md modification"
else
  fail "should detect hillchart.md"
fi

# Handover should exit silently
OUTPUT=$(run_ripple "/tmp/.shapeup/001-test/handover-01.md")
if [ -z "$OUTPUT" ]; then
  pass "handover exits silently (no ripple needed)"
else
  fail "handover should produce no output"
fi

echo ""
echo "=== Ripple Check: non-shapeup files ==="

OUTPUT=$(run_ripple "/tmp/src/app.ts")
if [ -z "$OUTPUT" ]; then
  pass "non-shapeup file produces no output"
else
  fail "should ignore non-shapeup files"
fi

echo ""
echo "=== Ripple Check: exit codes ==="

# All ripple checks should exit 0 (advisory, never blocking)
echo '{"tool_input": {"file_path": "/tmp/.shapeup/001/scopes/scope-backend.md"}}' | bash "$RIPPLE" 2>/dev/null
if [ $? -eq 0 ]; then
  pass "always exits 0 (advisory)"
else
  fail "should always exit 0"
fi

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All ripple check tests passed." || echo "$FAIL test(s) failed."
exit "$FAIL"
