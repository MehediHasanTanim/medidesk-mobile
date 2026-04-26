#!/usr/bin/env bash
# PostToolUse — WARN about bare print() calls in production Dart code.
# analysis_options.yaml enforces 'avoid_print'; debugPrint() or a logger should be used.

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

# Skip: non-Dart, generated, and test files
if [[ "$file_path" != *".dart" ]] \
   || [[ "$file_path" =~ \.(g|freezed)\.dart$ ]] \
   || [[ "$file_path" == *"/test/"* ]]; then
  exit 0
fi

if grep -qE "\bprint\(" "$file_path" 2>/dev/null; then
  count=$(grep -cE "\bprint\(" "$file_path" 2>/dev/null)
  echo "WARNING [lint]: $count bare print() call(s) in '$(basename "$file_path")'."
  echo "  • Use debugPrint() for debug output (stripped in release builds)"
  echo "  • analysis_options.yaml enforces 'avoid_print' — flutter analyze will flag these"
fi
