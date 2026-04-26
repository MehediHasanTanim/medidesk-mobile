#!/usr/bin/env bash
# PostToolUse — REMIND to run build_runner after changing files that drive code generation.
# Triggers on: Drift tables/DAOs, AppDatabase, @riverpod, @freezed, @JsonSerializable files.

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

# Never fire on already-generated files
if [[ "$file_path" =~ \.(g|freezed)\.dart$ ]]; then
  exit 0
fi

needs_codegen=false
reason=""

if [[ "$file_path" == *"/core/database/tables/"* ]]; then
  needs_codegen=true
  reason="Drift table definition changed"
elif [[ "$file_path" == *"/core/database/daos/"* ]]; then
  needs_codegen=true
  reason="Drift DAO changed"
elif [[ "$(basename "$file_path")" == "app_database.dart" ]]; then
  needs_codegen=true
  reason="AppDatabase registration changed"
elif grep -qE "@riverpod|@Riverpod|class \w+ extends _\$\w+|@freezed|@Freezed|@JsonSerializable|@DataClassName|@DriftAccessor" "$file_path" 2>/dev/null; then
  needs_codegen=true
  reason="Code-gen annotation detected in $(basename "$file_path")"
fi

if $needs_codegen; then
  echo "REMINDER [codegen]: $reason — regenerate before building:"
  echo "  cd medidesk && flutter pub run build_runner build --delete-conflicting-outputs"
fi
