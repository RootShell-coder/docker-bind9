
FROM alpine:latest

ENV TZ=Europe/Moscow
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl

RUN set -eux; \
  apk add --no-cache \
  pwgen \
  supervisor \
  bind bind-libs bind-tools bind-dnssec-tools \
  \
  musl musl-utils musl-locales \
  \
  tzdata patch; \
  rm -f /var/cache/apk/*; \
  rm -rf /etc/bind/*

COPY bind /etc/bind
COPY supervisor /etc/supervisor
COPY entrypoint /usr/sbin/entrypoint

RUN set -eux; \
  mkdir /var/log/named; \
  chown -R named:named /var/log/named/ /etc/bind/*; \
  chmod +x /usr/sbin/entrypoint; \
  find /etc/bind -name ".gitkeep" -type f -delete


VOLUME [ "/etc/bind" ]
EXPOSE 53 953 8080
ENTRYPOINT [ "entrypoint" ]
