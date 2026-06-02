# Self SNI Scripts — Rocky Linux Edition

Автоматическая установка и настройка Self SNI для Xray/V2Ray на Rocky Linux / AlmaLinux / RHEL.

## Что делает скрипт

Поднимает легитимный веб-сайт с валидным SSL-сертификатом на вашем сервере, чтобы использовать его как `target` в Reality вместо стороннего домена (например, `amd.com`). В результате сервер выглядит как настоящий веб-сайт — домен резолвится на ваш IP, сертификат реальный, сайт открывается.

```
Клиент → 443 (Xray/Reality) → 127.0.0.1:9000 (nginx) → отдаёт сайт
```

## Требования

- Rocky Linux / AlmaLinux / RHEL 8+
- Домен с A-записью, указывающей на IP сервера
- Открытые порты 80 и 443
- Root доступ

## Установка

```bash
curl -O https://raw.githubusercontent.com/WayneFX36/selfsni/refs/heads/main/selfsni.sh
chmod +x selfsni.sh
bash selfsni.sh
```

## Что спрашивает скрипт

| Параметр | Описание | По умолчанию |
|---|---|---|
| Доменное имя | Ваш домен с настроенной A-записью | — |
| SNI Self порт | Внутренний порт nginx (не торчит наружу) | `9000` |
| Шаблон сайта | Внешний вид сайта на домене | Случайный |

### Доступные шаблоны

| № | Название | Стиль |
|---|---|---|
| 1 | html5up-landed | Бизнес / Корпоративный |
| 2 | html5up-story | Портфолио / Агентство |
| 3 | html5up-phantom | Технологии / SaaS |
| 4 | html5up-editorial | Блог / Медиа |
| 5 | html5up-identity | Личный сайт |
| 6 | learning-zone (случайный) | Разные стили |

## После установки

Скрипт выведет параметры для подключения:

```
 Сертификат: /etc/letsencrypt/live/your.domain/fullchain.pem
 Ключ:       /etc/letsencrypt/live/your.domain/privkey.pem
 Dest:       127.0.0.1:9000
 SNI:        your.domain
```

### Конфиг Xray

Вставьте в `realitySettings` вашего конфига:

```json
"realitySettings": {
    "target": "127.0.0.1:9000",
    "serverNames": [
        "your.domain"
    ],
    "privateKey": "...",
    "shortIds": ["..."]
}
```

## Что устанавливается

- `nginx` — отдаёт сайт на порту 9000 (только локально)
- `certbot` + `python3-certbot-nginx` — SSL-сертификат Let's Encrypt
- `git`, `curl`, `bind-utils` — вспомогательные утилиты

Автопродление сертификата настраивается автоматически через systemd timer или cron.

## Отличие от обычного Reality

| | Обычный Reality | Self SNI |
|---|---|---|
| target | `amd.com:443` | `127.0.0.1:9000` |
| Домен указывает на ваш IP | ❌ | ✅ |
| Сертификат на вашем сервере | ❌ | ✅ |
| Сайт открывается по домену | ❌ | ✅ |
| Устойчивость к DPI/сканированию | Хорошая | Лучше |

## Совместимость

| ОС | Поддержка |
|---|---|
| Rocky Linux 8 / 9 | ✅ |
| AlmaLinux 8 / 9 | ✅ |
| RHEL 8 / 9 | ✅ |
| Ubuntu / Debian | ❌ (используйте оригинальный скрипт) |

## Оригинальный проект

Основан на [selfsniscripts by begugla](https://github.com/begugla0/selfsniscripts).
