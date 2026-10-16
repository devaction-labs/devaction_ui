#!/usr/bin/env bash
# Deploy a prebuilt image: pin releaseSource.pinnedVersion to a tag the
# `image` job already pushed to GHCR, POST /api/deployments, then poll until a
# terminal Openship status.
#
# The polling is the whole point. 202 "accepted" is not success — that was the
# v0.1.36 failure mode (HTTP 200/202, production still on the previous SHA),
# and `skipped` (Openship's incremental detector saying "Sem alterações") is a
# failure, not a no-op.
#
# No commitSha anywhere: the project is sourceKind=image / buildKind=prebuilt,
# where the image tag is the only thing that selects an artifact.
set -euo pipefail

if [ -z "${OPENSHIP_API_URL:-}" ] || [ -z "${OPENSHIP_API_TOKEN:-}" ] || [ -z "${OPENSHIP_PROJECT_ID:-}" ]; then
  echo "::error::Missing OPENSHIP_API_URL / OPENSHIP_API_TOKEN / OPENSHIP_PROJECT_ID"
  exit 1
fi

if [ -z "${IMAGE_VERSION:-}" ]; then
  echo "::error::Missing IMAGE_VERSION (a tag already in GHCR, e.g. v1.4.2 or sha-abc123)"
  exit 1
fi

LABEL="$IMAGE_VERSION"
API="${OPENSHIP_API_URL%/}"
AUTH=( -H "Authorization: Bearer ${OPENSHIP_API_TOKEN}" )

# Write only validated KEY=value lines. Never eval API-controlled strings.
parse_deploy_json() {
  local src="$1"
  local dest="$2"
  python3 - "$src" "$dest" <<'PY'
import json, re, sys
from pathlib import Path

src, dest = sys.argv[1], sys.argv[2]
raw = Path(src).read_text() or "{}"
try:
    body = json.loads(raw)
except json.JSONDecodeError:
    Path(dest).write_text("PARSE_OK=false\n")
    sys.exit(0)

data = body.get("data") or body
dep = data.get("deployment") if isinstance(data.get("deployment"), dict) else data
if not isinstance(dep, dict):
    dep = {}

dep_id = str(dep.get("id") or data.get("deployment_id") or data.get("id") or "")
status = str(dep.get("status") or "").lower()
skipped = data.get("skipped")

if not re.fullmatch(r"[A-Za-z0-9_-]*", dep_id):
    dep_id = ""
if not re.fullmatch(r"[a-z0-9_]*", status):
    status = "invalid"
skipped_s = "true" if skipped is True else "false"

Path(dest).write_text(
    f"PARSE_OK=true\nDEP_ID={dep_id}\nSTATUS={status}\nSKIPPED={skipped_s}\n"
)
PY
  # shellcheck disable=SC1090
  source "$dest"
}

# Point the project's releaseSource at the tag the `image` job pushed. This is
# a PUT of the whole source block, so mode/artifactKind/imageTemplate go with
# it every time — omitting them is a 400, not a partial update.
pin_image_version() {
  local template="${IMAGE_TEMPLATE:-ghcr.io/${GITHUB_REPOSITORY}:{version}}"
  local code
  code=$(curl -sS -o /tmp/openship-pin -w "%{http_code}" --max-time 60 \
    -X PUT "${API}/api/projects/${OPENSHIP_PROJECT_ID}/release-image-source" \
    "${AUTH[@]}" \
    -H "Content-Type: application/json" \
    -d "{\"mode\":\"github\",\"artifactKind\":\"image\",\"repo\":\"${GITHUB_REPOSITORY}\",\"imageTemplate\":\"${template}\",\"trackReleases\":false,\"pinnedVersion\":\"${IMAGE_VERSION}\"}" || true)
  echo "pin HTTP_CODE=$code image=${template/\{version\}/$IMAGE_VERSION}"
  case "$code" in
    200|201|204) ;;
    *)
      head -c 800 /tmp/openship-pin 2>/dev/null || true
      echo
      echo "::error::Could not pin image version '$IMAGE_VERSION' (HTTP $code) — not deploying"
      exit 1
      ;;
  esac
}

DEPLOY_BODY="{\"projectId\":\"${OPENSHIP_PROJECT_ID}\",\"environment\":\"production\",\"forceAll\":true}"

post_with_retry() {
  local attempt=1
  local max=4
  local sleep_s=5
  while [ "$attempt" -le "$max" ]; do
    local code
    code=$(curl -sS -o /tmp/openship-body -w "%{http_code}" --max-time 60 \
      -X POST "${API}/api/deployments" \
      "${AUTH[@]}" \
      -H "Content-Type: application/json" \
      -D /tmp/openship-headers \
      -d "$DEPLOY_BODY" || true)
    echo "HTTP_CODE=$code"
    echo "deploying=$LABEL"
    head -c 800 /tmp/openship-body 2>/dev/null || true
    echo
    case "$code" in
      200|201|202)
        return 0
        ;;
      429)
        local retry
        retry=$(awk -F': ' 'tolower($1)=="retry-after"{gsub(/\r/,"",$2); print $2; exit}' /tmp/openship-headers)
        sleep_s=${retry:-$sleep_s}
        echo "::warning::Openship 429 — retry $attempt/$max after ${sleep_s}s"
        ;;
      502|503|504)
        echo "::warning::Openship $code — retry $attempt/$max after ${sleep_s}s"
        ;;
      *)
        echo "::error::Unexpected status $code deploying $LABEL"
        exit 1
        ;;
    esac
    attempt=$((attempt + 1))
    sleep "$sleep_s"
    sleep_s=$((sleep_s * 2))
  done
  echo "::error::Openship POST still failing after $max attempts"
  exit 1
}

pin_image_version
post_with_retry

parse_deploy_json /tmp/openship-body /tmp/openship-parsed.env
if [ "${PARSE_OK}" != "true" ]; then
  echo "::error::Openship POST body is not JSON"
  exit 1
fi

if [ "${SKIPPED}" = "true" ]; then
  echo "::error::Openship skipped deploy of $LABEL (incremental no-op / already live). Production was not updated."
  exit 1
fi

if [ -z "${DEP_ID}" ]; then
  echo "::error::Openship accepted the request but returned no deployment id — cannot verify rollout"
  exit 1
fi

echo "deployment_id=$DEP_ID initial_status=${STATUS:-unknown}"

# In-flight: queued | building | deploying | reconciling
# Success: ready
# Failure / no-op: failed | rejected | cancelled | skipped | partial_failure | action_required
deadline=$((SECONDS + 1500))
sleep_s=10
while [ "$SECONDS" -lt "$deadline" ]; do
  code=$(curl -sS -o /tmp/openship-poll -w "%{http_code}" --max-time 30 \
    "${API}/api/deployments/${DEP_ID}" \
    "${AUTH[@]}" \
    -D /tmp/openship-poll-headers || true)

  if [ "$code" = "429" ]; then
    retry=$(awk -F': ' 'tolower($1)=="retry-after"{gsub(/\r/,"",$2); print $2; exit}' /tmp/openship-poll-headers)
    sleep "${retry:-$sleep_s}"
    continue
  fi

  if [ "$code" != "200" ]; then
    echo "::warning::GET /api/deployments/${DEP_ID} -> $code — retrying"
    sleep "$sleep_s"
    continue
  fi

  parse_deploy_json /tmp/openship-poll /tmp/openship-poll.env
  if [ "${PARSE_OK}" != "true" ]; then
    echo "::warning::Openship poll body is not JSON — retrying"
    sleep "$sleep_s"
    continue
  fi

  echo "Openship status=$STATUS"
  case "$STATUS" in
    ready)
      echo "Openship: $LABEL is ready ($DEP_ID)"
      exit 0
      ;;
    failed|rejected|cancelled|canceled|skipped|partial_failure|action_required|invalid)
      echo "::error::Openship deploy $DEP_ID ended as '$STATUS' — $LABEL is not in production"
      exit 1
      ;;
    queued|building|deploying|reconciling|"")
      sleep "$sleep_s"
      ;;
    *)
      echo "::warning::Unknown Openship status '$STATUS' — keep polling"
      sleep "$sleep_s"
      ;;
  esac
done

echo "::error::Timed out waiting for Openship deploy $DEP_ID to leave in-flight (last status=${STATUS:-unknown})"
exit 1
