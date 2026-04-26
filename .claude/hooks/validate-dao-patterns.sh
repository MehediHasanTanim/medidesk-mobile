#!/usr/bin/env bash
# PostToolUse — WARN when a DAO file violates the offline-first read/soft-delete contracts:
#   1. Read methods must return Stream<...>, never Future<List<...>>
#   2. Every query must filter isDeleted (soft-delete contract)

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

# Only inspect hand-written DAO files
if [[ "$file_path" != *"/core/database/daos/"* ]] || [[ "$file_path" =~ \.(g|freezed)\.dart$ ]]; then
  exit 0
fi

issues=()

# Rule 1: read methods must return Stream, not Future<List
if grep -qE "Future<List<[A-Za-z]" "$file_path" 2>/dev/null; then
  issues+=("Future<List<...>> found — read methods must return Stream<List<...>> (offline-first reactive requirement)")
fi

# Rule 2: soft-delete filter — if file contains Drift query builders, expect an isDeleted guard
if grep -qE "\(select\(|\bselectOnly\b|\bupdate\(|\bcustomSelect\b" "$file_path" 2>/dev/null; then
  if ! grep -qE "isDeleted|is_deleted" "$file_path" 2>/dev/null; then
    issues+=("No soft-delete filter — every DAO query MUST include 'isDeleted.equals(false)' (WHERE is_deleted = 0)")
  fi
fi

if [[ ${#issues[@]} -gt 0 ]]; then
  echo "WARNING [dao-patterns]: '$(basename "$file_path")' violates offline-first contracts:"
  for issue in "${issues[@]}"; do
    echo "  • $issue"
  done
  echo ""
  echo "Reference: features/patients/ — canonical offline-first DAO implementation."
fi
