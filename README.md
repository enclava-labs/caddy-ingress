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
ghcr.io/enclava-ai/caddy-ingress
```

The Kubernetes command is supplied by CAP. In production the container runs
Caddy through CAP's wait-exec/mounter contract so Caddy's ACME state lives on
the encrypted `tls-state` volume.

## Local Smoke Test

```sh
./scripts/smoke.sh
```

The smoke test verifies that the image builds, the Cloudflare DNS module is
absent, required tools exist, and a TLS-ALPN-only Caddyfile validates.
