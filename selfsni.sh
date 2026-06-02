#!/bin/bash

# Цвета для визуализации
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_progress() {
    local current=$1
    local total=$2
    local status=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] ${GREEN}%3d%%${NC} ${YELLOW}%s${NC}" "$percent" "$status"
}

show_complete() {
    echo -e "\n${GREEN}[OK]${NC} ${1}"
}

show_error() {
    echo -e "\n${RED}[ERROR]${NC} ${1}"
}

# Запуск команды со спиннером
run_with_spinner() {
    local cmd=$1
    local msg=$2
    local log_file="/tmp/sni_setup_$(date +%s)_$$.log"
    local spin=('|' '/' '-' '\\')
    local i=0

    eval "$cmd" >> "$log_file" 2>&1 &
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}${spin[$i]}${NC}  ${YELLOW}%s${NC}  " "$msg"
        i=$(( (i+1) % 4 ))
        sleep 0.15
    done

    wait "$pid"
    local exit_code=$?
    printf "\r                                                              \r"
    return $exit_code
}

clear
echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}  Установка и настройка Self SNI Scripts by begugla  ${NC}"
echo -e "${CYAN}     (Rocky Linux Edition)                           ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo ""

TOTAL_STEPS=14
CURRENT_STEP=0

# Шаг 1: Проверка системы
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Проверка операционной системы..."
sleep 0.3

if ! grep -Eiq "rocky|rhel|almalinux" /etc/os-release; then
    show_error "Система не поддерживается. Требуется Rocky Linux / AlmaLinux / RHEL."
    exit 1
fi
show_complete "Операционная система совместима"

# Шаг 2: Запрос данных
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Ожидание ввода данных..."
echo ""
read -p "Введите доменное имя: " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    show_error "Доменное имя не может быть пустым"
    exit 1
fi

read -p "Введите внутренний SNI Self порт (Enter для 9000): " SPORT
SPORT=${SPORT:-9000}

echo ""
echo -e "${CYAN}Выберите шаблон сайта:${NC}"
echo -e "  ${YELLOW}1)${NC} Бизнес / Корпоративный  (html5up-landed)"
echo -e "  ${YELLOW}2)${NC} Портфолио / Агентство   (html5up-story)"
echo -e "  ${YELLOW}3)${NC} Технологии / SaaS        (html5up-phantom)"
echo -e "  ${YELLOW}4)${NC} Блог / Медиа             (html5up-editorial)"
echo -e "  ${YELLOW}5)${NC} Личный сайт              (html5up-identity)"
echo -e "  ${YELLOW}6)${NC} Случайный из коллекции   (learning-zone)"
read -p "Введите номер шаблона (Enter для 6): " TEMPLATE_CHOICE
TEMPLATE_CHOICE=${TEMPLATE_CHOICE:-6}

case $TEMPLATE_CHOICE in
    1) TEMPLATE_URL="https://github.com/StartBootstrap/startbootstrap-creative.git"
       TEMPLATE_NAME="Бизнес / Корпоративный"
       WEBROOT="/usr/share/nginx/html/dist" ;;
    2) TEMPLATE_URL="https://github.com/StartBootstrap/startbootstrap-freelancer.git"
       TEMPLATE_NAME="Портфолио / Агентство"
       WEBROOT="/usr/share/nginx/html/dist" ;;
    3) TEMPLATE_URL="https://github.com/StartBootstrap/startbootstrap-new-age.git"
       TEMPLATE_NAME="Технологии / SaaS"
       WEBROOT="/usr/share/nginx/html/dist" ;;
    4) TEMPLATE_URL="https://github.com/StartBootstrap/startbootstrap-clean-blog.git"
       TEMPLATE_NAME="Блог / Медиа"
       WEBROOT="/usr/share/nginx/html/dist" ;;
    5) TEMPLATE_URL="https://github.com/StartBootstrap/startbootstrap-resume.git"
       TEMPLATE_NAME="Личный сайт"
       WEBROOT="/usr/share/nginx/html/dist" ;;
    *) TEMPLATE_URL="https://github.com/learning-zone/website-templates.git"
       TEMPLATE_NAME="Случайный из коллекции"
       WEBROOT="/usr/share/nginx/html"
       TEMPLATE_CHOICE=6 ;;
esac

show_complete "Параметры получены (шаблон: $TEMPLATE_NAME)"

# Шаг 3: Обновление пакетов
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Обновление списка пакетов..."
if run_with_spinner "dnf makecache -y" "Обновление списка пакетов..."; then
    show_complete "Список пакетов обновлен"
else
    show_error "Не удалось обновить список пакетов"
    exit 1
fi

# Шаг 4: Установка EPEL
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Установка EPEL репозитория..."
if run_with_spinner "dnf install -y epel-release" "Установка EPEL..."; then
    show_complete "EPEL репозиторий установлен"
else
    show_error "Не удалось установить EPEL"
    exit 1
fi

# Шаг 4б: Установка компонентов
show_progress $CURRENT_STEP $TOTAL_STEPS "Установка nginx, certbot, git..."
if run_with_spinner "dnf install -y nginx certbot python3-certbot-nginx git curl bind-utils" "Установка компонентов (это может занять несколько минут)..."; then
    show_complete "Компоненты успешно установлены"
else
    show_error "Не удалось установить необходимые компоненты"
    exit 1
fi

# Шаг 5: Внешний IP
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Определение внешнего IP сервера..."
external_ip=$(curl -s --max-time 5 https://api.ipify.org)
if [[ -z "$external_ip" ]]; then
    show_error "Не удалось определить внешний IP сервера"
    exit 1
fi
show_complete "Внешний IP сервера: $external_ip"

# Шаг 6: DNS
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Проверка A-записи домена..."
domain_ip=$(dig +short A "$DOMAIN" | head -n1)
if [[ -z "$domain_ip" ]]; then
    show_error "Не удалось получить A-запись для домена $DOMAIN"
    echo -e "${YELLOW}Подробнее: https://github.com/begugla0/selfsniscripts${NC}"
    exit 1
fi
show_complete "A-запись домена: $domain_ip"

# Шаг 7: Сравнение IP
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Проверка соответствия DNS записи..."
if [[ "$domain_ip" != "$external_ip" ]]; then
    show_error "A-запись домена не соответствует внешнему IP сервера"
    echo -e "${YELLOW}Подробнее: https://github.com/begugla0/selfsniscripts${NC}"
    exit 1
fi
show_complete "DNS записи корректны"

# Шаг 8: Остановка nginx
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Остановка nginx..."
systemctl stop nginx 2>/dev/null || true
show_complete "Nginx остановлен"

# Шаг 9: Проверка портов
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Проверка портов 80 и 443..."
if ss -tuln | grep -q ":443 "; then
    show_error "Порт 443 занят"
    exit 1
fi
if ss -tuln | grep -q ":80 "; then
    show_error "Порт 80 занят"
    exit 1
fi
show_complete "Порты 80 и 443 свободны"

# Шаг 10: firewalld
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Открытие портов в firewalld..."
if systemctl is-active --quiet firewalld; then
    run_with_spinner "firewall-cmd --permanent --add-service=http && firewall-cmd --permanent --add-service=https && firewall-cmd --reload" "Настройка firewalld..."
    show_complete "Порты 80 и 443 открыты в firewalld"
else
    show_complete "firewalld не активен, пропуск"
fi

# Шаг 11: Шаблон сайта
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Загрузка шаблона сайта..."
TEMP_DIR=$(mktemp -d)
if run_with_spinner "git clone --depth 1 $TEMPLATE_URL $TEMP_DIR" "Клонирование шаблона $TEMPLATE_NAME..."; then
    if [[ "$TEMPLATE_CHOICE" == "6" ]]; then
        SITE_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | shuf -n 1)
        cp -r "$SITE_DIR"/* /usr/share/nginx/html/ 2>/dev/null
    else
        cp -r "$TEMP_DIR"/* /usr/share/nginx/html/ 2>/dev/null
    fi
    show_complete "Шаблон сайта установлен ($TEMPLATE_NAME)"
else
    show_error "Не удалось загрузить шаблон сайта"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Шаг 12: SSL сертификат
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Получение SSL сертификата..."
if run_with_spinner "certbot certonly --standalone -d $DOMAIN --agree-tos -m admin@$DOMAIN --non-interactive" "Получение SSL сертификата (может занять время)..."; then
    show_complete "SSL сертификат успешно получен"
else
    show_error "Не удалось получить SSL сертификат"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Автопродление
if systemctl list-timers 2>/dev/null | grep -q certbot.timer; then
    systemctl enable certbot.timer 2>/dev/null || true
    systemctl start certbot.timer 2>/dev/null || true
    if ! systemctl cat certbot.timer 2>/dev/null | grep -q "Persistent=true"; then
        mkdir -p /etc/systemd/system/certbot.timer.d/
        cat > /etc/systemd/system/certbot.timer.d/override.conf <<'EOF'
[Timer]
Persistent=true
EOF
        systemctl daemon-reload
        systemctl restart certbot.timer
    fi
    show_complete "Автопродление настроено (systemd timer)"
elif [ -f /etc/cron.d/certbot ]; then
    show_complete "Автопродление настроено (cron)"
else
    cat > /etc/cron.d/certbot <<'CRONEOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 */12 * * * root certbot -q renew --nginx
CRONEOF
    show_complete "Автопродление настроено (новый cron)"
fi

run_with_spinner "certbot renew --dry-run" "Проверка автопродления..." || true

# Шаг 13: Конфиг nginx
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Создание конфигурации Nginx..."

rm -f /etc/nginx/conf.d/default.conf

cat > /etc/nginx/conf.d/sni.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    if (\$host = $DOMAIN) {
        return 301 https://\$host\$request_uri;
    }

    return 404;
}

server {
    listen 127.0.0.1:$SPORT ssl http2;

    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";

    real_ip_header proxy_protocol;
    set_real_ip_from 127.0.0.1;

    location / {
        root $WEBROOT;
        try_files \$uri \$uri/ /index.html;
        index index.html;
    }
}
EOF

run_with_spinner "setsebool -P httpd_can_network_connect 1" "Настройка SELinux..." || true
show_complete "Конфигурация Nginx создана"

# Шаг 14: Запуск nginx
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress $CURRENT_STEP $TOTAL_STEPS "Запуск и включение Nginx..."

if nginx -t > /dev/null 2>&1 && \
   systemctl enable nginx > /dev/null 2>&1 && \
   systemctl start nginx > /dev/null 2>&1; then
    show_complete "Nginx успешно запущен и добавлен в автозагрузку"
else
    show_error "Ошибка при запуске Nginx"
    rm -rf "$TEMP_DIR"
    exit 1
fi

rm -rf "$TEMP_DIR"

echo ""
echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}          Установка завершена успешно!              ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo ""
echo -e "${GREEN}Параметры для подключения:${NC}"
echo -e "${BLUE}-----------------------------------------------------${NC}"
echo -e " ${YELLOW}Сертификат:${NC} /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo -e " ${YELLOW}Ключ:${NC}        /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo -e " ${YELLOW}Dest:${NC}        127.0.0.1:$SPORT"
echo -e " ${YELLOW}SNI:${NC}         $DOMAIN"
echo -e "${BLUE}-----------------------------------------------------${NC}"
echo ""
echo -e "${GREEN}Скрипт завершен!${NC}"
