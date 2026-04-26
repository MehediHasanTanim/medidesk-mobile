#!/usr/bin/env bash
# PreToolUse — BLOCK direct edits to lock / package-config files.
# pubspec.lock must only be updated via 'flutter pub get'.
# package_config.json must only be updated via build_runner / pub get.

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

basename_file=$(basename "$file_path")

case "$basename_file" in
  pubspec.lock)
    echo "BLOCKED: 'pubspec.lock' must not be edited directly."
    echo "Run 'flutter pub get' (or 'flutter pub upgrade <pkg>') to update it."
    exit 2
    ;;
  package_config.json)
    echo "BLOCKED: 'package_config.json' is managed by the Dart toolchain."
    echo "Run 'flutter pub get' to regenerate it."
    exit 2
    ;;
esac
