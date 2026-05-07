#!/bin/sh
set -eu

IMAGE="${1:-caddy-ingress:local}"

docker build -t "$IMAGE" .

tmpdir="$(mktemp -d)"
cleanup() {
  docker run --rm -v "$tmpdir:/host" "$IMAGE" sh -c \
    'chmod -R 0777 /host 2>/dev/null || true; rm -rf /host/*' \
    >/dev/null 2>&1 || true
  rm -rf "$tmpdir"
}
trap cleanup EXIT

if docker run --rm "$IMAGE" caddy list-modules | grep -F "dns.providers.cloudflare"; then
  echo "Cloudflare DNS module must not be present in the TLS-ALPN-only image" >&2
  exit 1
fi
docker run --rm "$IMAGE" sh -eu -c '
  command -v caddy
  command -v enclava-wait-exec
  command -v cryptsetup
  command -v mkfs.ext4
  command -v curl
  command -v wget
'

mkdir -p "$tmpdir/run"
chmod 0777 "$tmpdir/run"
: > "$tmpdir/run/init-ready"
docker run --rm --user 10001:10001 \
  -e ENCLAVA_CONTAINER_NAME=web \
  -e ENCLAVA_STARTED_DIR=/run/enclava/containers \
  -e ENCLAVA_INIT_READY_FILE=/run/enclava/init-ready \
  -v "$tmpdir/run:/run/enclava" \
  "$IMAGE" /usr/local/bin/enclava-wait-exec true
docker run --rm --user 10002:10002 \
  -e ENCLAVA_CONTAINER_NAME=tenant-ingress \
  -e ENCLAVA_STARTED_DIR=/run/enclava/containers \
  -e ENCLAVA_INIT_READY_FILE=/run/enclava/init-ready \
  -v "$tmpdir/run:/run/enclava" \
  "$IMAGE" /usr/local/bin/enclava-wait-exec true

cat > "$tmpdir/Caddyfile" <<'CADDY'
{
  email ops@enclava.dev
}

example.enclava.dev {
  tls {
    issuer acme {
      disable_http_challenge
    }
  }
  respond "ok"
}
CADDY

docker run --rm \
  -v "$tmpdir/Caddyfile:/etc/caddy/Caddyfile:ro" \
  "$IMAGE" caddy validate --config /etc/caddy/Caddyfile
