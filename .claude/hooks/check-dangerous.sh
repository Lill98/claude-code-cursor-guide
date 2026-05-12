#!/bin/bash
# Block dangerous shell commands before Claude executes them

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Block rm -rf on root or very short paths (not project subdirectories)
if echo "$COMMAND" | grep -qE "rm -rf[[:space:]]+/$|rm -rf[[:space:]]+/tmp[[:space:]]|rm -rf[[:space:]]+~[[:space:]]"; then
    echo "BLOCKED: Dangerous rm on system path: $COMMAND" >&2
    exit 2
fi

# Block destructive DB operations
if echo "$COMMAND" | grep -qiE "DROP[[:space:]]+(TABLE|DATABASE)|TRUNCATE[[:space:]]+TABLE"; then
    echo "BLOCKED: Destructive database operation prevented: $COMMAND" >&2
    exit 2
fi

# Block force push to remote
if echo "$COMMAND" | grep -qE "git push.*(--force|-f)([[:space:]]|$)"; then
    echo "BLOCKED: Force push prevented: $COMMAND" >&2
    exit 2
fi

exit 0
