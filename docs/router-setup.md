# 🔌 Настройка VLESS Reality на роутере Keenetic / OpenWrt

> После настройки **весь трафик домашней сети** идёт через VLESS Reality. Никаких настроек на телефонах и ноутбуках — просто подключились к Wi-Fi.

---

## Вариант 1: Keenetic (через Entware + Podkop)

**Podkop** — специальный пакет для Keenetic, который настраивает обход блокировок на уровне роутера.

### Требования

- Роутер Keenetic с прошивкой 3.7+
- Установленный Entware (через OPKG в Keenetic OS)
- VPS с VLESS Reality

### Установка

```bash
# Подключиться к Keenetic по SSH
ssh admin@192.168.1.1

# Обновить OPKG
opkg update

# Установить podkop
opkg install podkop

# Запустить сервис
/etc/init.d/podkop start
```

### Конфигурация podkop

Редактируем файл настроек:

```bash
vi /etc/podkop/config
```

Содержимое файла:
```
PROXY_TYPE=vless
PROXY_ADDR=ВАШ_IP_СЕРВЕРА
PROXY_PORT=443
UUID=ВАШ_UUID
FLOW=xtls-rprx-vision
SECURITY=reality
SNI=www.apple.com
PUBLIC_KEY=ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ
SHORT_ID=ВАШ_SHORT_ID
FINGERPRINT=chrome
MODE=selective
```

Режим `selective` означает — через VPN идут только заблокированные в РФ ресурсы (YouTube, Instagram, ChatGPT и т.д.), остальное напрямую.

### Обновление списка блокировок

```bash
# Обновить список заблокированных доменов
podkop update

# Перезапустить
/etc/init.d/podkop restart
```

---

## Вариант 2: OpenWrt (через XRay-core)

### Установка XRay на OpenWrt

```bash
# Обновить пакеты
opkg update

# Установить xray
opkg install xray-core

# Установить luci-app-xray (веб-интерфейс, опционально)
opkg install luci-app-xray
```

### Конфигурация /etc/xray/config.json

```json
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": { "auth": "noauth", "udp": true }
    },
    {
      "port": 8080,
      "listen": "0.0.0.0",
      "protocol": "http"
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [{
          "address": "ВАШ_IP_СЕРВЕРА",
          "port": 443,
          "users": [{
            "id": "ВАШ_UUID",
            "flow": "xtls-rprx-vision",
            "encryption": "none"
          }]
        }]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "serverName": "www.apple.com",
          "publicKey": "ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ",
          "shortId": "ВАШ_SHORT_ID"
        }
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:ru", "geoip:private"],
        "outboundTag": "direct"
      }
    ]
  }
}
```

### Настройка iptables для прозрачного прокси

```bash
# Перенаправить трафик через xray (transparent proxy)
iptables -t nat -N XRAY
iptables -t nat -A XRAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A XRAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A XRAY -d 192.168.0.0/16 -j RETURN
iptables -t nat -A XRAY -d 10.0.0.0/8 -j RETURN
iptables -t nat -A XRAY -p tcp -j REDIRECT --to-ports 1080
iptables -t nat -A PREROUTING -p tcp -j XRAY
```

### Автозапуск

```bash
/etc/init.d/xray enable
/etc/init.d/xray start
```

---

## Проверка что всё работает

С любого устройства в домашней сети:

```
curl https://api.ipify.org
# Должен показать IP вашего VPS, не домашний IP
```

Или откройте [2ip.ru](https://2ip.ru) — должен показать страну вашего сервера.

---

## Полезные ссылки

- 📖 [Официальная документация Podkop](https://github.com/itdoginfo/podkop)
- 📖 [XRay на OpenWrt wiki](https://openwrt.org/docs/guide-user/services/proxy/xray)
- 📖 [Детальный гайд на vpn-rating.space](https://vpn-rating.space/articles/whole-home-keenetic-openwrt-vless-setup.html)

---

📖 [Вернуться к основному README](../README.md)
