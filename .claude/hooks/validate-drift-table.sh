#!/usr/bin/env bash
# PostToolUse — WARN if a newly written Drift table is missing required offline-sync columns.
# Every mutable table must carry: server_id, sync_status, is_deleted, deleted_at, last_modified

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

# Only inspect hand-written table definitions
if [[ "$file_path" != *"/core/database/tables/"* ]] || [[ "$file_path" =~ \.(g|freezed)\.dart$ ]]; then
  exit 0
fi

# Dart getters use camelCase; accept either camelCase or snake_case naming
missing=()

grep -qE "serverId|server_id"       "$file_path" 2>/dev/null || missing+=("serverId")
grep -qE "syncStatus|sync_status"   "$file_path" 2>/dev/null || missing+=("syncStatus")
grep -qE "isDeleted|is_deleted"     "$file_path" 2>/dev/null || missing+=("isDeleted")
grep -qE "deletedAt|deleted_at"     "$file_path" 2>/dev/null || missing+=("deletedAt")
grep -qE "lastModified|last_modified" "$file_path" 2>/dev/null || missing+=("lastModified")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "WARNING [drift-table]: '$(basename "$file_path")' is missing required offline-sync columns:"
  for col in "${missing[@]}"; do
    echo "  • $col"
  done
  echo ""
  echo "Every mutable Drift table MUST define all five sync columns."
  echo "See medidesk/ARCHITECTURE.md — New Entity Checklist."
fi
