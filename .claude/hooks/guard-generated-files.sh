#!/usr/bin/env bash
# PreToolUse — BLOCK direct edits to Dart code-generated files.
# Generated files (*.g.dart, *.freezed.dart) must only be produced by build_runner.

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

if [[ "$file_path" =~ \.(g|freezed)\.dart$ ]]; then
  echo "BLOCKED: '$(basename "$file_path")' is a generated file and must not be edited manually."
  echo ""
  echo "Regenerate with:"
  echo "  cd medidesk && flutter pub run build_runner build --delete-conflicting-outputs"
  exit 2
fi
