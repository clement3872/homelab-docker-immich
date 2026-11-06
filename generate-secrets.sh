#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  cp .env.example "$ENV_FILE"
  echo "Created .env from .env.example"
fi

_inject() {
  local key="$1"
  if grep -qP "^${key}=\s*$" "$ENV_FILE"; then
    local secret
    secret=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s|^${key}=.*|${key}=${secret}|" "$ENV_FILE"
    echo "  Generated ${key}"
  else
    echo "  ${key} already set, skipping"
  fi
}

echo "Generating secrets..."
_inject DB_PASSWORD

echo ""
echo "Done. Fill in IMMICH_URL and DOMAIN manually in .env."
