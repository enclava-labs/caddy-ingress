# caddy-ingress

Tenant ingress image for Enclava confidential workloads.

This image is the Caddy sidecar used by CAP-generated tenant pods. It includes:

- Caddy without DNS-provider plugins. Tenant ACME is TLS-ALPN-01 only.
- `cryptsetup` and `e2fsprogs`, retained for compatibility with older
  secure-PV bootstrap paths.
- `curl` and `wget`, used by health/resource fetch paths.
- `/usr/local/bin/enclava-wait-exec`, the wait helper CAP uses before
  starting Caddy against encrypted tenant state.

Published image:

```text
ghcr.io/enclava-labs/caddy-ingress
```

The Kubernetes command is supplied by CAP. In production the container runs
Caddy through CAP's wait-exec/mounter contract so Caddy's ACME state lives on
the encrypted `tls-state` volume.

## Base Image Provenance

Both base stages are pinned by digest so rebuilds are reproducible and the
bundled Go toolchain and CA store are fixed:

- `caddy:${CADDY_VERSION}-builder` via `CADDY_BUILDER_DIGEST`
  (`sha256:8910fe662f448b860e8d16ef1c9a4f8946d3193bdc3e971bf0c55c9a2cf246f6`
  for 2.11.7, bundles Go 1.27.3). `xcaddy build` compiles from the Caddy
  2.11.7 source tag inside that image.
- `alpine:3.22` runtime stage
  (`sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8`).

When rotating `CADDY_VERSION`, resolve the new builder digest and update
`CADDY_BUILDER_DIGEST` in the same change:

```sh
docker pull "caddy:${CADDY_VERSION}-builder"
docker image inspect --format '{{index .RepoDigests 0}}' "caddy:${CADDY_VERSION}-builder"
```

## Local Smoke Test

```sh
./scripts/smoke.sh
```

The smoke test verifies that the image builds, the Cloudflare DNS module is
absent, required tools exist, and a TLS-ALPN-only Caddyfile validates.
