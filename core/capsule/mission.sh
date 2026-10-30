#!/usr/bin/env bash
set -euo pipefail

CAPSULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="$CAPSULE_DIR/secrets.env"

NETWORK="mission-net"
VOLUME="mission-logs"
AGENT_IMAGE="sid-lab02-slim"
STORAGE_IMAGE="alpine:3.20"

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "ERROR: $SECRETS_FILE not found, copy it from secrets.env.example" >&2
  exit 1
fi

echo "==> Building capsule image..."
docker build -q -f "$CAPSULE_DIR/Dockerfile.slim" -t "$AGENT_IMAGE" "$CAPSULE_DIR" >/dev/null

echo "==> Preparing network and shared volume..."
docker network create "$NETWORK" >/dev/null 2>&1 || true
docker volume create "$VOLUME" >/dev/null

echo "==> Starting storage and agent..."
docker rm -f agent storage >/dev/null 2>&1 || true

docker run -d --name storage --network "$NETWORK" \
  -v "$VOLUME:/data" \
  "$STORAGE_IMAGE" sleep infinity >/dev/null

# The capsule binary exits right away, so the agent stays alive on sleep.
docker run -d --name agent --network "$NETWORK" \
  -v "$VOLUME:/data" \
  --env-file "$SECRETS_FILE" \
  --entrypoint sleep \
  "$AGENT_IMAGE" infinity >/dev/null

echo "Mission containers are running."
