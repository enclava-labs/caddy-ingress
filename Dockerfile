ARG CADDY_VERSION=2.11.7
# Digest of caddy:${CADDY_VERSION}-builder (bundles Go 1.27.3, 2026-10-20 build);
# rotate together with CADDY_VERSION, see README "Base image provenance".
ARG CADDY_BUILDER_DIGEST=sha256:8910fe662f448b860e8d16ef1c9a4f8946d3193bdc3e971bf0c55c9a2cf246f6

FROM caddy:${CADDY_VERSION}-builder@${CADDY_BUILDER_DIGEST} AS builder

RUN xcaddy build

FROM alpine:3.22@sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8

RUN apk add --no-cache \
    ca-certificates \
    curl \
    e2fsprogs \
    libcap \
    cryptsetup \
    tzdata \
    wget

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY enclava-wait-exec /usr/local/bin/enclava-wait-exec

RUN setcap cap_net_bind_service=+ep /usr/bin/caddy \
    && chmod 0755 /usr/local/bin/enclava-wait-exec \
    && addgroup -S caddy \
    && adduser -S -D -H -h /var/lib/caddy -s /sbin/nologin -G caddy caddy \
    && mkdir -p /config/caddy /data/caddy /var/lib/caddy \
    && chown -R caddy:caddy /config /data /var/lib/caddy

EXPOSE 80 443 443/udp

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
