#!/bin/sh
set -eu

IMAGE="${1:-caddy-ingress:local}"

docker build -t "$IMAGE" .

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
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
