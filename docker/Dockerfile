FROM alpine:3.18

ARG S6_OVERLAY_VERSION=3.2.2.0

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp

RUN set -eux; \
  apk update && apk upgrade; \
  apk add --no-cache \
    bind \
    bind-libs \
    bind-tools \
    bind-dnssec-tools \
    openssl \
    tzdata \
    fail2ban \
    iptables \
    ip6tables; \
  tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
  tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz; \
  rm -rf /tmp/* /var/cache/apk/* /etc/bind/*; \
  mkdir -p /etc/bind

COPY ./bind /etc/bind
COPY ./services.d /etc/services.d
COPY ./cont-init.d /etc/cont-init.d
COPY ./fail2ban/jail.local /etc/fail2ban/jail.local
COPY ./fail2ban/filter.d /etc/fail2ban/filter.d

RUN chmod +x /etc/services.d/*/run /etc/cont-init.d/*

WORKDIR /etc/bind
ENTRYPOINT ["/init"]
