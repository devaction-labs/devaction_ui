#!/usr/bin/env bash

set -euo pipefail

required=(
  OPENSHIP_API_URL
  OPENSHIP_API_TOKEN
  OPENSHIP_PROJECT_ID
  SECRET_KEY_BASE
  PHX_HOST
  PORT
)

for name in "${required[@]}"; do
  if [ -z "${!name:-}" ]; then
    echo "::error::Missing ${name}"
    exit 1
  fi
done

payload=$(mktemp)
response=$(mktemp)
trap 'rm -f "$payload" "$response"' EXIT

jq -n \
  --arg secret_key_base "$SECRET_KEY_BASE" \
  --arg phx_host "$PHX_HOST" \
  --arg port "$PORT" \
  '{
    environment: "production",
    deletes: [],
    upserts: [
      {key: "SECRET_KEY_BASE", value: $secret_key_base, isSecret: true},
      {key: "PHX_HOST", value: $phx_host, isSecret: false},
      {key: "PORT", value: $port, isSecret: false}
    ]
  }' > "$payload"

code=$(curl -sS -o "$response" -w '%{http_code}' --max-time 60 \
  -X PATCH "${OPENSHIP_API_URL%/}/api/projects/${OPENSHIP_PROJECT_ID}/env" \
  -H "Authorization: Bearer ${OPENSHIP_API_TOKEN}" \
  -H 'Content-Type: application/json' \
  --data-binary "@$payload")

case "$code" in
  200|201|204)
    echo "Openship production runtime environment synchronized"
    ;;
  *)
    reason=$(jq -r '[.error, .message, .code] | map(select(type == "string")) | join(" · ")' "$response" 2>/dev/null || true)
    keys=$(jq -r '[.upserts[].key] | join(", ")' "$payload")
    echo "::error::Could not synchronize Openship runtime environment (HTTP $code): ${reason:-no readable reason}"
    echo "Keys sent: $keys"
    exit 1
    ;;
esac
