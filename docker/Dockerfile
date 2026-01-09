FROM alpine:latest

ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.2/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.2/s6-overlay-x86_64.tar.xz /tmp

RUN set -eux; \
  apk update; \
  apk add --no-cache \
  bind \
  bind-libs \
  bind-tools \
  bind-dnssec-tools \
  openssl \
  tzdata \
  curl \
  haveged; \
  rm -f /var/cache/apk/*; \
  rm -rf /etc/bind/*; \
\
  tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
  tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz; \
  rm -rf /tmp/*

COPY ./bind /etc/bind
COPY ./services.d /etc/services.d
COPY ./cont-init.d /etc/cont-init.d
RUN chmod +x /etc/services.d/*/run /etc/cont-init.d/*

WORKDIR /etc/bind
ENTRYPOINT ["/init"]
