#!/bin/bash
# lint-fix.sh — PostToolUse hook
# Reads file_path from stdin JSON and runs ESLint --fix on .ts/.tsx files.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only process TypeScript files
case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Only process files that actually exist
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Run ESLint --fix, suppressing output on success
if command -v eslint &>/dev/null; then
  eslint --fix "$FILE_PATH" 2>&1
elif [ -f "./node_modules/.bin/eslint" ]; then
  ./node_modules/.bin/eslint --fix "$FILE_PATH" 2>&1
fi

exit 0
