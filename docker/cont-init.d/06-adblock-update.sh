#!/bin/sh

# Скрипт для обновления списка блокировки рекламы от StevenBlack
# Конвертирует список хостов в формат RPZ для BIND
# Версия для Alpine Linux (sh)

set -e

log()   { echo "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] $1\033[0m"; }
warn()  { echo "\033[1;33m[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1\033[0m"; }
error() { echo "\033[0;31m[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"; }

# Проверяем переменную ADBLOCK
if [ "${DNS_ADBLOCK:-false}" != "true" ]; then
    log "Adblock disabled (ADBLOCK != true), skipping..."
    exit 0
fi

# Конфигурация
HOSTS_URL="${ADBLOCK_HOSTS_URL:-https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/data/StevenBlack/hosts}"
RPZ_FILE="${ADBLOCK_RPZ_FILE:-/etc/bind/adblock/db.rpz.adblock}"

HOSTS_FILE="/tmp/black_hosts"
TEMP_RPZ_FILE="/tmp/db.rpz.adblock.tmp"
SERIAL=$(date +%Y%m%d%H)

# Если скрипт запускается как cont-init.d (при старте контейнера)
case "$0" in
    *cont-init.d*)
        echo "Setting up ad blocking system..."

        # Создаем директорию для adblock
        mkdir -p /etc/bind/adblock
        mkdir -p /usr/local/bin
        mkdir -p /var/log

        # Копируем скрипт обновления в /usr/local/bin (копирует сам себя)
        cp "$0" /usr/local/bin/update-adblock.sh
        chmod +x /usr/local/bin/update-adblock.sh

        # Создаем cron задачу для обновления каждые 6 часов (Alpine Linux)
        mkdir -p /etc/crontabs
        echo "0 */6 * * * /usr/local/bin/update-adblock.sh >> /var/log/adblock-update.log 2>&1" >> /etc/crontabs/root
        chmod 600 /etc/crontabs/root

        echo "Performing initial adblock list update..."
        # Выполняем первоначальное обновление
        /usr/local/bin/update-adblock.sh

        echo "Ad blocking system configured successfully"
        exit 0
        ;;
esac

# Функция для создания RPZ заголовка
create_rpz_header() {
    cat > "$TEMP_RPZ_FILE" << EOF
\$TTL 300
\$ORIGIN rpz.adblock.
@   IN  SOA rpz.adblock. admin.rpz.adblock. (
    ${SERIAL}  ; Serial number (YYYYMMDDHH)
    3600       ; Refresh (1 hour)
    600        ; Retry (10 minutes)
    604800     ; Expire (1 week)
    300        ; Minimum TTL (5 minutes)
)
    IN  NS  localhost.

; Generated on: $(date)
; Source: ${HOSTS_URL}
; Total domains will be appended below

EOF
}

# Основная функция
main() {
    log "Starting ad blocking list update..."

    # Создаем каталог если не существует
    mkdir -p /etc/bind/adblock

    # Скачиваем список хостов
    log "Downloading Black hosts list..."
    if ! curl -s -f -o "$HOSTS_FILE" "$HOSTS_URL"; then
        error "Failed to download hosts list"
        exit 1
    fi

    # Проверяем что файл скачался и не пустой
    if [ ! -s "$HOSTS_FILE" ]; then
        error "Downloaded file is empty or corrupted"
        exit 1
    fi

    log "Hosts list downloaded successfully ($(wc -l < "$HOSTS_FILE") lines)"

    # Создаем заголовок RPZ файла
    log "Creating RPZ file..."
    create_rpz_header

    # Обрабатываем список хостов и конвертируем в RPZ формат
    log "Converting domains to RPZ format..."

    domains_count=0

    # Обрабатываем каждую строку файла хостов
    while IFS= read -r line; do
        # Пропускаем комментарии и пустые строки
        case "$line" in
            \#*) continue ;;
            "") continue ;;
        esac

        # Удаляем пробелы в начале и конце
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Проверяем формат: 0.0.0.0 domain или 127.0.0.1 domain
        case "$line" in
            0.0.0.0\ *|127.0.0.1\ *)
                # Извлекаем домен (все после первого пробела)
                domain=$(echo "$line" | cut -d' ' -f2- | tr -d '\r' | sed 's/[[:space:]]*$//')

                # Проверяем что домен не пустой и содержит точку
                if [ -n "$domain" ] && echo "$domain" | grep -q '\.'; then
                    # Простая проверка валидности домена (содержит буквы/цифры и точки)
                    if echo "$domain" | grep -q '^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$'; then
                        # Добавляем домен в RPZ файл
                        echo "${domain} CNAME ." >> "$TEMP_RPZ_FILE"
                        # Также добавляем wildcard для поддоменов
                        echo "*.${domain} CNAME ." >> "$TEMP_RPZ_FILE"
                        domains_count=$((domains_count + 1))
                    fi
                fi
                ;;
        esac
    done < "$HOSTS_FILE"

    log "Processed domains: $domains_count"

    # Добавляем статистику в конец файла
    echo "; Total domains blocked: $domains_count" >> "$TEMP_RPZ_FILE"
    echo "; Last updated: $(date)" >> "$TEMP_RPZ_FILE"

    # Проверяем что новый файл содержит домены
    if [ "$domains_count" -lt 1000 ]; then
        warn "Too few domains processed ($domains_count). Check the source."
    fi

    # Атомарно заменяем файл
    mv "$TEMP_RPZ_FILE" "$RPZ_FILE"

    # Устанавливаем правильные права доступа
    chmod 644 "$RPZ_FILE"
    chown bind:bind "$RPZ_FILE" 2>/dev/null || true

    log "RPZ file created: $RPZ_FILE"
    log "Domains blocked: $domains_count"

    # Перезагружаем зону в BIND
    if command -v rndc >/dev/null 2>&1; then
        log "Reloading RPZ zone in BIND..."
        if rndc reload rpz.adblock 2>/dev/null; then
            log "Zone rpz.adblock reloaded successfully"
        else
            warn "Failed to reload zone via rndc. BIND may not be configured yet."
        fi
    else
        warn "rndc not found. Manual BIND reload required."
    fi

    # Очищаем временные файлы
    rm -f "$HOSTS_FILE"

    log "Ad blocking list update completed successfully!"
}

# Запуск основной функции
main "$@"
