# 🛡️ VLESS Reality — Полный гайд по настройке (2026)

> **Самый подробный open-source гайд** по настройке протокола VLESS Reality (XRay Core) на русском языке. Обходит DPI ТСПУ РКН, работает на МТС, Билайн, Мегафон, Ростелеком, Т2 в 2026 году.

[![GitHub stars](https://img.shields.io/github/stars/yurac777/vless-reality-guide?style=social)](https://github.com/yurac777/vless-reality-guide)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Last Updated](https://img.shields.io/badge/Updated-July%202026-blue)](https://github.com/yurac777/vless-reality-guide)
[![Telegram Bot](https://img.shields.io/badge/Telegram-@space__tunnel__bot-blue?logo=telegram)](https://t.me/space_tunnel_bot)

---

## 🔥 Почему VLESS Reality, а не WireGuard / OpenVPN?

В 2026 году ТСПУ РКН перешли на **третье поколение DPI** — статистический анализ трафика и машинное обучение. Результат:

| Протокол | Статус в РФ 2026 | Скорость (тест 1 Гбит) | Причина блокировки |
|----------|-----------------|------------------------|--------------------|
| **WireGuard** | ❌ Блокируется за 2 мс | 0 Мбит/с | Жёсткий байтовый отпечаток пакета Type 1 со смещением `0x01` |
| **OpenVPN UDP** | ❌ Полностью заблокирован | 12 Мбит/с | Фиксированная длина управляющих пакетов + HMAC-сигнатура |
| **Shadowsocks** | ⚠️ TCP Freeze через 15 сек | нестабильно | Характерная высокая энтропия зашифрованного хвоста |
| **AmneziaWG** | ⚠️ Частично (МТС, РТК) | нестабильно | Junk-пакеты вычисляются по временным задержкам |
| **VLESS Reality** | ✅ **Невидим для ТСПУ** | **920 Мбит/с** | Неотличим от TLS 1.3 трафика к Apple / Google |

---

## 🔬 Как работают ТСПУ и почему VLESS Reality невидим

### Эволюция DPI РКН (2018 → 2026)

**1-е поколение (2018–2021)** — блокировка по статическим правилам:
- Чёрные списки IP-адресов
- Анализ URL в открытых HTTP-заголовках
- Блокировка стандартных портов (OpenVPN UDP 1194, WireGuard UDP 51820)

**2-е поколение (2022–2024)** — анализ SNI и сигнатур протоколов:
- Чтение имени сервера в открытом заголовке `ClientHello` при TLS-рукопожатии
- Поиск фиксированных байтовых сигнатур в начале сессии

**3-е поколение (Лето 2026)** — Stateful Packet Inspection + машинный анализ:
- **JA3/JA4 Fingerprinting**: Анализ структуры TLS-рукопожатия (порядок шифров, список расширений)
- **Packet Size Distribution**: Проверка длины первых 5–10 пакетов — у VPN-протоколов характерные математические паттерны
- **Inter-Arrival Time Analysis**: Оценка временных пауз между пакетами
- Время анализа сессии: **< 1.5 мс** без ощутимой задержки для пользователя

### Механика «TCP Freeze» — самый коварный инструмент ТСПУ 2026

Вместо явного RST-сброса ТСПУ **тихо отбрасывают пакеты подтверждения TCP ACK**:

```
1️⃣ Клиент  →  SYN  →  Сервер         ✅ Пропускает
2️⃣ Клиент  ←  SYN-ACK  ←  Сервер     ✅ Пропускает
3️⃣ Клиент  →  ACK  →  [ТСПУ]         ❌ Тихо уничтожает
4️⃣ Клиент ждёт ответа... Тайм-аут... Повтор... 🧊 Заморозка
```

Результат: на экране горит **«Подключено»**, но скорость = 0 Кбит/с. Именно это происходит с WireGuard, OpenVPN и Shadowsocks.

### Почему VLESS Reality невидим

**VLESS Reality** использует **Stealth Camouflage** — маскируется под обычный TLS 1.3:

1️⃣ **Настоящий TLS Handshake**: При анализе ТСПУ сервер отдаёт действительный сертификат `apple.com` или `dl.google.com`. Для DPI — это обычный визит на сайт Apple.

2️⃣ **uTLS Impersonation (JA4 Spoofing)**: Клиент подменяет криптографический отпечаток, полностью имитируя браузер Google Chrome на Windows 11 или Safari на iOS.

3️⃣ **Active Probing Protection**: Если ТСПУ отправит тестовый запрос на IP вашего сервера — Reality перенаправит его на настоящий сайт Google. DPI получит валидный ответ и занесёт IP в список доверенных.

---

## 📊 Реальные бенчмарки (Июль 2026, Ростелеком Москва → Франкфурт)

| Протокол | Входящая | Исходящая | Пинг RTT | Стабильность 24/7 |
|----------|----------|-----------|----------|-------------------|
| Без VPN (прямой) | 940 Мбит/с | 920 Мбит/с | 32 мс | ❌ YouTube/Discord заблокированы |
| WireGuard | 0 Мбит/с | 0 Мбит/с | — | ❌ 0% |
| OpenVPN UDP | 12 Мбит/с | 8 Мбит/с | 110 мс | ❌ 0% |
| **VLESS Reality (TCP Vision)** | **920 Мбит/с** | **900 Мбит/с** | **34 мс** | ✅ **100%** |
| VLESS + XHTTP/REALITY | 880 Мбит/с | 850 Мбит/с | 35 мс | ✅ 100% |
| Hysteria 2 | 850 Мбит/с | 800 Мбит/с | 33 мс | ✅ 98% |

> Тест: гигабитный канал Ростелеком, инструмент `speedtest-cli`, среднее из 3 замеров.

---

## 📋 Содержание

- [Требования к серверу](#требования-к-серверу)
- [Установка XRay Core / 3X-UI](#установка-xray-core)
- [Настройка на Windows (v2rayN)](docs/windows-setup.md)
- [Настройка на Android (v2rayNG)](docs/android-setup.md)
- [Настройка на iOS (Streisand / Happ)](docs/ios-setup.md)
- [Настройка на роутере Keenetic / OpenWrt](docs/router-setup.md)
- [Split Tunneling для геймеров](docs/gaming-split-tunneling.md)
- [Доступ к ChatGPT / OpenAI API без 403](docs/chatgpt-access.md)
- [FAQ и решение проблем](docs/faq.md)

---

## 🖥️ Требования к серверу

| Параметр | Минимум | Рекомендуется |
|---------|---------|---------------|
| ОС | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS / Debian 12 |
| RAM | 512 МБ | 1 ГБ+ |
| CPU | 1 vCPU | 2 vCPU |
| Трафик | 500 ГБ/мес | 1–2 ТБ/мес |
| Порт 443 | Свободен | Свободен |
| Расположение | Любая страна кроме РФ/РБ/КЗ | Нидерланды, Германия, Финляндия, Латвия |

**Подходящие хостинги** (принимают оплату из РФ):
- **Hetzner** (Германия/Финляндия) — от €4/мес, лучший выбор
- **Aeza** (Нидерланды) — от €3/мес, принимает рубли
- **ServerSpace** (Нидерланды) — от 350 ₽/мес, оплата картой РФ

---

## 🚀 Установка XRay Core

### Авто-установщик (одна команда)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/yurac777/vless-reality-guide/main/install.sh)
```

Скрипт автоматически:
- Устанавливает XRay Core
- Генерирует UUID, X25519 ключи, Short ID
- Записывает `config.json`
- Настраивает systemd сервис
- Выводит строку `vless://...` и QR-код

### Через панель 3X-UI (рекомендуется для начинающих)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
```

После установки панель доступна по адресу `http://ВАШ_IP:2053`.

### Генерация ключей вручную

```bash
# UUID для пользователя
xray uuid

# Пара ключей X25519 для Reality
xray x25519
# Вывод:
# Private key: <приватный ключ — только на сервере>
# Public key:  <публичный ключ — в конфиг клиента>
```

---

## ⚙️ Конфигурации сервера

Готовые шаблоны конфигурации в папке [`configs/`](configs/):

- [`server-config-example.json`](configs/server-config-example.json) — базовый VLESS Reality
- [`client-config-example.json`](configs/client-config-example.json) — клиент с Split Tunneling
- [`server-xhttp-example.json`](configs/server-xhttp-example.json) — VLESS + XHTTP (для мобильных сетей)

---

## 📱 Клиентские приложения

### Windows
| Приложение | Описание | Ссылка |
|-----------|----------|--------|
| **v2rayN** | Лучший выбор, поддерживает TUN-режим | [GitHub](https://github.com/2dust/v2rayN/releases) |
| Hiddify | Простой интерфейс | [GitHub](https://github.com/hiddify/hiddify-app) |
| NekoRay | Продвинутые настройки маршрутизации | [GitHub](https://github.com/MatsuriDayo/nekoray) |

### Android
| Приложение | Ссылка |
|-----------|--------|
| **v2rayNG** | [Google Play](https://play.google.com/store/apps/details?id=com.v2ray.ang) / [GitHub](https://github.com/2dust/v2rayNG/releases) |
| Hiddify | [Google Play](https://play.google.com/store/apps/details?id=app.hiddify.com) |
| Happ | [Google Play](https://play.google.com/store/apps/details?id=com.happ.vpn) |

### iOS
| Приложение | Цена | Ссылка |
|-----------|------|--------|
| **Streisand** | Бесплатно | [App Store](https://apps.apple.com/app/streisand/id6450534064) |
| Happ | Бесплатно | [App Store](https://apps.apple.com/app/happ-proxy-utility/id6504287215) |
| FoXray | $3.99 | [App Store](https://apps.apple.com/app/foxray/id6448898396) |

### macOS
| Приложение | Ссылка |
|-----------|--------|
| Hiddify | [GitHub](https://github.com/hiddify/hiddify-app) |
| V2Box | [App Store](https://apps.apple.com/app/v2box-v2ray-client/id6446814690) |

---

## 🎮 Split Tunneling — для геймеров и разработчиков

Правильная архитектура:
```
Discord Voice / ChatGPT / YouTube → VLESS Reality → ✅ Работает
CS2 / Valorant / Dota 2           → Прямой путь  → ⚡ Пинг 20 мс
Банки / Госуслуги / Яндекс        → Прямой путь  → ⚡ Максимальная скорость
```

Результаты тестов (CS2, сервер Стокгольм):
- Без VPN: **22 мс** / WireGuard: **115 мс** / VLESS Split Tunneling: **22 мс**

Подробный гайд: [docs/gaming-split-tunneling.md](docs/gaming-split-tunneling.md)

---

## 🤖 ChatGPT / OpenAI API без ошибки 403

Cloudflare Bot Management в 2026 блокирует запросы через публичные VPN по 3 критериям:
- **IP Reputation Index**: Публичные VPS Hetzner/DigitalOcean помечены как ботнеты
- **JA3/JA4 Fingerprinting**: Стандартные VPN имеют отличные от Chrome отпечатки
- **Геолокационные прыжки**: Смена IP страны = подозрение на взлом аккаунта

VLESS Reality решает все три проблемы — статический IP + Chrome fingerprint + стабильный регион.

Совместимость с OpenAI (Июль 2026):
- GPT-5.6 Sol / Terra / Luna: ✅ 100%
- OpenAI o3 / o3-mini: ✅ 100%
- OpenAI Sora 2 (4K Video): ✅ 4K рендеринг без срывов
- OpenAI API (Python/TS SDK): ✅ 30 мс пинг

Подробнее: [docs/chatgpt-access.md](docs/chatgpt-access.md)

---

## 🏠 Настройка на роутере — VPN для всей семьи

Keenetic с модулем **Podkop + sing-box** за 5 шагов:

1. Откройте `192.168.1.1` → **«Управление»** → **«Компоненты»**
2. Найдите **«Поддержка протокола VLESS / sing-box (Podkop)»**, активируйте
3. В меню **«Podkop»** вставьте вашу VLESS-строку
4. Нажмите **«Сохранить и включить»**
5. Готово — весь дом защищён!

Совместимые модели Keenetic: Titan (KN-1811/1810), Hero (KN-1011/1010), Hopper (KN-3810), Sprinter (KN-3710), Extra (KN-1711).

Подробнее: [docs/router-setup.md](docs/router-setup.md)

---

## 🧪 Готовое решение без настройки VPS

Если не хотите тратить время на аренду и настройку Linux-сервера — готовая инфраструктура VLESS Reality:

**🤖 [@space_tunnel_bot](https://t.me/space_tunnel_bot)** — персональный ключ за 10 секунд, 3 дня бесплатно без карты.

Промокоды для читателей:
- `GITHUB_VLESS` — базовый тест
- `VC_GAMING` — Split Tunneling для геймеров (Discord + игры)
- `VC_HOME` — семейный доступ (роутер Keenetic)

---

## 🔗 Полезные ссылки

- 📖 [Физика ТСПУ и VLESS Reality: полный разбор](https://vpn-rating.space/articles/tspu-rkn-vless-reality-physics-guide-2026.html)
- 📖 [Keenetic + Podkop для всей семьи](https://vpn-rating.space/articles/whole-home-keenetic-openwrt-vless-setup.html)
- 📖 [YouTube 4K без буферизации на Smart TV](https://vpn-rating.space/articles/youtube-4k-keenetic-podkop-smart-tv-fix.html)
- 📖 [ChatGPT 5.6 без ошибки 403](https://vpn-rating.space/articles/chatgpt5-openai-403-vless-bypass-2026.html)
- 📖 [Discord Voice Fix + геймерский пинг](https://vpn-rating.space/articles/discord-voice-rtc-gaming-ping-fix-2026.html)
- 🌐 [Каталог VPN-ботов с оплатой по СБП](https://vpn-rating.space)
- 📦 [XRay Core](https://github.com/XTLS/Xray-core)
- 📦 [3X-UI Panel](https://github.com/MHSanaei/3x-ui)
- 📦 [Podkop для Keenetic](https://github.com/itdoginfo/podkop)

---

## 📄 Лицензия

MIT License — используй свободно, ссылка на репозиторий приветствуется.

---

*Гайд обновлён: Июль 2026 | XRay Core v26.6.27 | Проверено на МТС, Билайн, Мегафон, Ростелеком, Т2*
