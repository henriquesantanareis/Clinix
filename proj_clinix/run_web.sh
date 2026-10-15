#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="$project_dir/config/supabase.json"

if [[ ! -f "$config_file" ]]; then
  printf 'Missing %s. Copy config/supabase.example.json to config/supabase.json and add your Supabase URL and publishable key.\n' "$config_file" >&2
  exit 1
fi

if ! python3 -c 'import json, sys
try:
    config = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, ValueError):
    sys.exit(1)
sys.exit(0 if config.get("SUPABASE_URL") and config.get("SUPABASE_PUBLISHABLE_KEY") else 1)' "$config_file"; then
  printf 'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in config/supabase.json before launching.\n' >&2
  exit 1
fi

exec flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  --dart-define-from-file="$config_file" \
  "$@"