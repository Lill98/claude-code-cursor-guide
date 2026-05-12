#!/bin/bash
# prettier-fix.sh — PostToolUse hook
# Reads file_path from stdin JSON and runs Prettier --write on
# .ts/.tsx/.json/.prisma files.

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

# Only process supported file types
case "$FILE_PATH" in
  *.ts|*.tsx|*.json|*.prisma) ;;
  *) exit 0 ;;
esac

# Only process files that actually exist
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Run Prettier --write, suppressing output on success
if command -v prettier &>/dev/null; then
  prettier --write "$FILE_PATH" 2>&1
elif [ -f "./node_modules/.bin/prettier" ]; then
  ./node_modules/.bin/prettier --write "$FILE_PATH" 2>&1
fi

exit 0
