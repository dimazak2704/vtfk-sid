#!/usr/bin/env bash
set -euo pipefail

IMAGE="ubuntu:24.04"
CONTAINER="sid-capsule"
PRIVATE_CONTAINER="sid-capsule-private"

echo "==> Removing old containers if they exist..."
docker rm -f "$CONTAINER" "$PRIVATE_CONTAINER" >/dev/null 2>&1 || true

echo "==> Starting main capsule with port 8080 -> 80..."
docker run -d \
  --name "$CONTAINER" \
  -p 8080:80 \
  "$IMAGE" \
  sleep infinity >/dev/null

echo "==> Installing required tools..."
docker exec "$CONTAINER" bash -c '
  apt-get update &&
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    procps \
    iproute2 \
    python3
'

echo "==> Starting HTTP server..."
docker exec -d "$CONTAINER" \
  python3 -m http.server 80

echo "==> Starting second capsule without published ports..."
docker run -d \
  --name "$PRIVATE_CONTAINER" \
  "$IMAGE" \
  sleep infinity >/dev/null

docker exec "$PRIVATE_CONTAINER" bash -c '
  apt-get update &&
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3
'

docker exec -d "$PRIVATE_CONTAINER" \
  python3 -m http.server 80

echo "==> Checking isolation without published port..."

docker stop "$CONTAINER" >/dev/null

echo "Negative HTTP check:"
if curl -i --connect-timeout 2 http://localhost:8080/; then
  echo "ERROR: localhost:8080 is unexpectedly reachable" >&2
  exit 1
else
  echo "PASS: container without -p is not reachable from the host"
fi

docker start "$CONTAINER" >/dev/null
docker exec -d "$CONTAINER" \
  python3 -m http.server 80

echo "==> Waiting for HTTP server..."
for _ in {1..20}; do
  if curl -fsS http://localhost:8080/ >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo
echo "Deployment completed."
echo "Main container:    $CONTAINER"
echo "Private container: $PRIVATE_CONTAINER"

echo
echo "Published ports:"
docker port "$CONTAINER"

echo
echo "Installed tools:"
docker exec "$CONTAINER" bash -c '
  curl --version | head -1
  git --version
  ps --version | head -1
  ip -Version
'

echo
echo "HTTP check:"
curl -I http://localhost:8080/