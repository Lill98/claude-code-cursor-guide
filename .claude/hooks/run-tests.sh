#!/bin/bash
# run-tests.sh — Stop hook
# Runs the Vitest test suite after Claude finishes a response.
# Exit 0 always — Stop hooks are informational and non-blocking.

echo "Running tests..."

if command -v vitest &>/dev/null; then
  vitest --run 2>&1
  STATUS=$?
elif [ -f "./node_modules/.bin/vitest" ]; then
  ./node_modules/.bin/vitest --run 2>&1
  STATUS=$?
else
  echo "vitest not found — skipping test run"
  exit 0
fi

if [ $STATUS -eq 0 ]; then
  echo "Tests passed."
else
  echo "Tests failed (exit $STATUS). Review the output above."
fi

# Always exit 0 — Stop hooks should not block Claude
exit 0
