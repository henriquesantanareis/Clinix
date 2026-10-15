#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="$project_dir/config/supabase.json"

if ! command -v flutter >/dev/null 2>&1 && [[ -x "$HOME/flutter/bin/flutter" ]]; then
  export PATH="$HOME/flutter/bin:$PATH"
fi

if [[ ! -f "$config_file" ]]; then
  printf 'Falta %s. Copie o arquivo config/supabase.example.json para config/supabase.json e adicione a sua URL do Supabase e a sua chave publicável.' "$config_file" >&2
  exit 1
fi

if ! python3 -c 'import json, sys
try:
    config = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, ValueError):
    sys.exit(1)
sys.exit(0 if config.get("SUPABASE_URL") and config.get("SUPABASE_PUBLISHABLE_KEY") else 1)' "$config_file"; then
  printf 'Defina SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY em config/supabase.json antes de lançar.\n' >&2
  exit 1
fi

exec flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  --dart-define-from-file="$config_file" \
  "$@"