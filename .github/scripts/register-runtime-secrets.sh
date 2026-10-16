#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 PATH_TO_PRIVATE_ENV_FILE"
  exit 2
fi

secret_file="$1"
if [ ! -f "$secret_file" ]; then
  echo "error: secret file not found: $secret_file"
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$secret_file"
set +a

required=(
  OPENSHIP_CLOUD_API_URL
  OPENSHIP_CLOUD_API_TOKEN
  OPENSHIP_CLOUD_PROJECT_ID
)

for name in "${required[@]}"; do
  if [ -z "${!name:-}" ]; then
    echo "error: missing ${name} in ${secret_file}"
    exit 2
  fi
done

repository="devaction-labs/devaction_ui"
secret_key_base="${SECRET_KEY_BASE:-$(openssl rand -base64 48 | tr -d '\n')}"

for name in "${required[@]}"; do
  printf '%s' "${!name}" | gh secret set "$name" --repo "$repository"
done

printf '%s' "$secret_key_base" | gh secret set SECRET_KEY_BASE --repo "$repository"

gh variable set PHX_HOST --body "${PHX_HOST:-ui.devaction.ia.br}" --repo "$repository"
gh variable set PORT --body 4000 --repo "$repository"

echo "GitHub runtime secrets and variables registered for ${repository}"
