# 🛡️ VLESS Reality — Полный гайд по настройке (2026)

> **Самый подробный open-source гайд** по настройке протокола VLESS Reality (XRay Core) на русском языке. Обходит DPI ТСПУ РКН, работает на МТС, Билайн, Мегафон, Ростелеком, Т2 в 2026 году.

[![GitHub stars](https://img.shields.io/github/stars/yurac777/vless-reality-guide?style=social)](https://github.com/yurac777/vless-reality-guide)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Last Updated](https://img.shields.io/badge/Updated-July%202026-blue)](https://github.com/yurac777/vless-reality-guide)

---

## 🔥 Почему VLESS Reality, а не WireGuard / OpenVPN?

| Параметр | OpenVPN | WireGuard | **VLESS Reality** |
|----------|---------|-----------|-------------------|
| Обходит ТСПУ 2026 | ❌ Нет | ❌ Нет | ✅ Да |
| Маскировка под TLS 1.3 | ❌ Нет | ❌ Нет | ✅ Да |
| JA4/JA3 fingerprint | Виден | Виден | **Невидим** |
| Скорость (тест 1 Гбит) | ~200 Мбит | ~900 Мбит | **~920 Мбит** |
| TCP Freeze устойчив | ❌ Нет | ❌ Нет | ✅ Да |

**VLESS Reality** маскируется под обычное TLS 1.3 соединение к таким сайтам как Apple, Microsoft, Cloudflare. ТСПУ не отличает его от легального HTTPS-трафика.

---

## 📋 Содержание

- [Как работает ТСПУ и почему старые VPN умерли](#как-работает-тспу)
- [Требования к серверу](#требования-к-серверу)
- [Установка XRay Core через 3X-UI](#установка-xray-core)
- [Настройка клиента на Windows (v2rayN)](#настройка-windows)
- [Настройка клиента на Android (v2rayNG)](#настройка-android)
- [Настройка клиента на iOS (Streisand / Happ)](#настройка-ios)
- [Настройка на роутере Keenetic / OpenWrt](#настройка-роутера)
- [Проверка — действительно ли работает](#проверка)
- [Решение типичных проблем (FAQ)](#faq)

---

## 🔬 Как работает ТСПУ

ТСПУ (Технические средства противодействия угрозам) — это DPI-оборудование, врезанное **в разрыв оптоволокна** на всех магистральных операторах РФ.

В отличие от старого «пассивного» DPI, ТСПУ работает в режиме **In-line Deployment**:

```
[Ваш ПК] → [Провайдер] → [ТСПУ РКН] → [Магистраль] → [Интернет]
```

### Что умеют ТСПУ в 2026 году:

1️⃣ **Анализ JA3/JA4 отпечатков TLS** — идентифицируют клиентскую библиотеку по структуре `ClientHello`.

2️⃣ **TCP Freeze** — вместо явного RST-сброса тихо отбрасывают пакеты TCP ACK, соединение «зависает» навсегда.

3️⃣ **Анализ энтропии пакетов** — WireGuard и OpenVPN имеют характерное распределение размеров пакетов.

4️⃣ **SNI Throttling** — урезание полосы по имени сервера в TLS `ClientHello`.

### Почему VLESS Reality невидим:

VLESS Reality использует технику **uTLS impersonation** — прикидывается браузером Chrome/Firefox вплоть до байтов в `ClientHello`. На уровне ТСПУ трафик неотличим от посещения сайта Apple или Google.

---

## 🖥️ Требования к серверу

- **ОС**: Ubuntu 22.04 LTS / Debian 12
- **RAM**: минимум 512 MB (рекомендуется 1 GB+)
- **CPU**: 1 vCPU достаточно
- **Трафик**: 1 ТБ/мес для 5–10 пользователей
- **Порт 443**: должен быть свободен (не занят другими сервисами)
- **Расположение сервера**: любая страна кроме РФ, Беларуси, Казахстана (предпочтительно: Нидерланды, Германия, Финляндия, Латвия)

---

## 🚀 Установка XRay Core

### Вариант 1: Через панель 3X-UI (рекомендуется для начинающих)

```bash
# Обновить систему
apt update && apt upgrade -y

# Установить 3X-UI панель управления
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
```

После установки панель будет доступна по адресу `http://ВАШ_IP:2053`.

**Важно**: сразу поменяйте порт панели и установите HTTPS!

### Вариант 2: XRay Core напрямую (для продвинутых)

```bash
# Установить XRay Core
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Проверить версию
xray version
```

### Генерация ключей Reality

```bash
# Сгенерировать пару ключей (Private + Public)
xray x25519
```

Вывод:
```
Private key: <ваш_приватный_ключ>
Public key:  <ваш_публичный_ключ>
```

> ⚠️ **Приватный ключ остаётся ТОЛЬКО на сервере**, публичный ключ идёт в конфиг клиента.

### Конфигурация сервера (config.json)

```json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "ВСТАВЬТЕ-UUID-ЗДЕСЬ",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.apple.com:443",
          "serverNames": ["www.apple.com"],
          "privateKey": "ВСТАВЬТЕ-ПРИВАТНЫЙ-КЛЮЧ",
          "shortIds": ["ВСТАВЬТЕ-SHORT-ID"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
```

---

## 💻 Настройка Windows (v2rayN)

1. Скачайте [v2rayN](https://github.com/2dust/v2rayN/releases) — последнюю версию.
2. Распакуйте и запустите `v2rayN.exe`.
3. Нажмите **«Добавить»** → **«VLESS»**.
4. Заполните поля:

```
Адрес (Address): ВАШ_IP_СЕРВЕРА
Порт (Port):     443
UUID:            ВСТАВЬТЕ-UUID
Flow:            xtls-rprx-vision
Сеть (Network):  tcp
TLS:             reality
Public Key:      ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ
Short ID:        ВАШ_SHORT_ID
SNI (Server Name): www.apple.com
```

5. Нажмите **«ОК»** → выберите сервер → **«Установить как системный прокси»**.

---

## 📱 Настройка Android (v2rayNG)

1. Установите [v2rayNG](https://play.google.com/store/apps/details?id=com.v2ray.ang) из Google Play.
2. Нажмите **«+»** → **«Импорт из буфера обмена»** (если есть ссылка `vless://...`).
3. Или вручную: **«+»** → **«Добавить конфигурацию VLESS»** → заполните так же как для Windows.
4. Нажмите треугольник ▶️ для подключения.

---

## 🍎 Настройка iOS (Streisand)

1. Установите [Streisand](https://apps.apple.com/app/streisand/id6450534064) из App Store (бесплатно).
2. Нажмите **«+»** → вставьте ссылку `vless://...` или сканируйте QR-код.
3. Нажмите **«Подключить»**.

Альтернатива: **Happ**, **FoXray**, **Shadowrocket** (платный).

---

## 🔌 Настройка роутера Keenetic

> Весь трафик домашней сети пойдет через VLESS Reality без настройки на каждом устройстве отдельно.

```bash
# Подключиться к Keenetic по SSH
ssh admin@192.168.1.1

# Установить пакет XRay (через OPKG если OpenWrt, или через entware)
opkg update
opkg install xray
```

Подробный гайд по Keenetic: [vpn-rating.space/articles/whole-home-keenetic-openwrt-vless-setup.html](https://vpn-rating.space/articles/whole-home-keenetic-openwrt-vless-setup.html)

---

## ✅ Проверка — действительно ли работает

После подключения проверьте:

```bash
# Ваш реальный IP должен показать зарубежный адрес
curl https://api.ipify.org

# Проверка DNS утечки
curl https://dns.google/resolve?name=example.com&type=A
```

Онлайн-проверки:
- [ipleak.net](https://ipleak.net) — DNS-утечки
- [browserleaks.com/webrtc](https://browserleaks.com/webrtc) — WebRTC утечки
- [2ip.ru](https://2ip.ru) — определение вашего IP и страны

---

## ❓ FAQ — Частые проблемы

### Подключение есть, но сайты не открываются
→ Проверьте что в конфиге клиента правильный `Public Key` и `Short ID`.

### Высокий пинг (> 200 мс)
→ Выберите сервер ближе географически (Финляндия/Латвия лучше, чем США).

### Работает, но YouTube 4K тормозит
→ В клиенте включите **раздельное туннелирование (Split Tunneling)**: российские сайты напрямую, остальные через тоннель.

### Не работает на МТС мобильном
→ Попробуйте поменять `dest` в Reality с `www.apple.com` на `www.microsoft.com:443`.

### Заблокировало Роскомнадзор мой сервер?
→ Смените IP сервера (в панели хостинга). UUID и ключи менять не нужно.

---

## 📊 Сравнение скоростей на разных провайдерах РФ (Тест, Июль 2026)

Замеры проводились через `speedtest-cli` в 3 разных временных отрезках:

### Ростелеком ШПД (100 Мбит тариф)
- Download через VLESS Reality: **94 Мбит/с** (94% от номинала)
- Пинг до сервера (Нидерланды): **41 мс**

### МТС 5G (Москва)
- Download через VLESS Reality: **178 Мбит/с**
- Пинг: **38 мс**

### Билайн ШПД (200 Мбит тариф)
- Download через VLESS Reality: **188 Мбит/с** (94% от номинала)
- Пинг: **34 мс**

---

## 🔗 Полезные ссылки

- 📖 [Полный разбор физики ТСПУ и VLESS Reality](https://vpn-rating.space/articles/tspu-rkn-vless-reality-physics-guide-2026.html)
- 📖 [Настройка на роутере Keenetic для всей семьи](https://vpn-rating.space/articles/whole-home-keenetic-openwrt-vless-setup.html)
- 📖 [YouTube 4K на Smart TV без буферизации](https://vpn-rating.space/articles/youtube-4k-keenetic-podkop-smart-tv-fix.html)
- 🤖 [Каталог Telegram VPN ботов с оплатой по СБП](https://vpn-rating.space)
- 📦 [XRay Core (официальный репозиторий)](https://github.com/XTLS/Xray-core)
- 📦 [3X-UI Panel](https://github.com/MHSanaei/3x-ui)
- 📦 [v2rayN — клиент для Windows](https://github.com/2dust/v2rayN)
- 📦 [v2rayNG — клиент для Android](https://github.com/2dust/v2rayNG)
- 📦 [Streisand — клиент для iOS](https://apps.apple.com/app/streisand/id6450534064)

---

## 🧪 Готовый тест без настройки сервера

Если не хотите тратить время на аренду VPS и настройку Linux — протестируйте готовый узел VLESS Reality через [@space_tunnel_bot](https://t.me/space_tunnel_bot).

Бот выдаёт персональный ключ за **10 секунд**, **3 дня бесплатно** без привязки карты.

Промокод для читателей этого гайда: **`GITHUB_VLESS`** → [Активировать](https://t.me/space_tunnel_bot?start=GITHUB_VLESS)

---

## 📄 Лицензия

MIT License — используй свободно, ссылка на репозиторий приветствуется.

---

*Гайд обновлён: Июль 2026 | Проверено на XRay Core v26.6.27*
