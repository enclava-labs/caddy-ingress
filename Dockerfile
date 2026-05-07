ARG CADDY_VERSION=2.10.2

FROM caddy:${CADDY_VERSION}-builder AS builder

RUN xcaddy build

FROM alpine:3.22

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
