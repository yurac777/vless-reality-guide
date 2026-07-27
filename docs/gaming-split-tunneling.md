# 🎮 Split Tunneling для геймеров — Discord Voice + минимальный пинг в CS2/Valorant

## Проблема: Почему обычный VPN портит игры

При включении классического VPN **весь трафик** идёт через сервер:

```
ПК Геймера → VPN Сервер (Франкфурт) → Сервер CS2 (Стокгольм)
                    ↑
             Трафик делает крюк +80 мс к пингу!
```

Результат: пинг в CS2 с 22 мс вырастает до 115 мс. Фризы, рывки персонажа, проигранные раунды.

### Почему Discord Voice зависает («RTC Connecting»)

Discord использует **WebRTC** — голосовые потоки передаются по протоколу **UDP** на случайных портах `50000–65535`. ТСПУ РКН:
- Блокирует диапазон портов и IP серверов Discord RTC
- Вычисляет зашифрованный сигнальный запрос при открытии голосового канала и разрывает TCP-сессию

---

## Решение: Split Tunneling (Раздельное туннелирование)

Правильная архитектура для геймера:

```
                   ┌──→  Discord Voice + YouTube + ChatGPT  ──→  VLESS Reality  ──→  ✅
ПК Геймера ────────┤
                   └──→  CS2 / Valorant / Dota 2  ──→  Прямой путь провайдера  ──→  ⚡ 22 мс
```

1. **Игровые пакеты** (CS2, Valorant, Dota 2, PUBG) — напрямую через провайдера, минимальный пинг
2. **Discord Voice + заблокированные ресурсы** — через VLESS Reality

---

## 📊 Сравнение результатов (Тест, Июль 2026)

### CS2 — сервер Стокгольм
| Режим | Пинг | Packet Loss |
|-------|------|-------------|
| Без VPN (прямой) | ⚡ 22 мс | 0% |
| Обычный WireGuard | 🐢 115 мс | 5–15% |
| **VLESS Split Tunneling** | ⚡ **22 мс** | **0%** |

### Valorant — сервер Франкфурт
| Режим | Пинг | Packet Loss |
|-------|------|-------------|
| Без VPN (прямой) | ⚡ 35 мс | 0% |
| Обычный WireGuard | 🐢 120 мс | 5–15% |
| **VLESS Split Tunneling** | ⚡ **35 мс** | **0%** |

### Discord Voice (RTC)
| Режим | Результат |
|-------|-----------|
| Без VPN (прямой) | ❌ RTC Connecting |
| Обычный WireGuard | ✅ Работает |
| **VLESS Split Tunneling** | ✅ **100% Идеально** |

---

## ⚙️ Настройка в v2rayN (Windows) — 2 минуты

1. Запустите **v2rayN**, добавьте VLESS Reality подписку
2. Откройте вкладку **«Маршрутизация» (Routing)**
3. Выберите режим **«Bypass LAN and Direct Game»**
4. В **«Настройки маршрутизации»** → список проксируемых доменов добавьте:

```
geosite:discord
domain:discord.com
domain:discord.gg
domain:discordapp.net
domain:discord.media
domain:discordapp.com
```

5. Включите **System Proxy**

Теперь Discord работает через VLESS, CS2 идёт напрямую — пинг не изменился.

---

## ⚙️ Настройка в v2rayNG (Android)

1. Откройте v2rayNG → **☰** → **«Настройки»**
2. **«Тип маршрута»** → **«GeoIP»**
3. В разделе **«Пользовательские правила»** добавьте:

```
# Прямое подключение — игры
domain:mm.battlenet.com.cn,direct
ip:162.254.192.0/18,direct

# Через прокси — Discord
domain:discord.com,proxy
domain:discord.gg,proxy
domain:discordapp.net,proxy
```

---

## 🔌 Настройка на роутере Keenetic (для консолей и Smart TV)

Модуль **Podkop / sing-box** на Keenetic автоматически применяет Split Tunneling для всех устройств:

- PlayStation 5, Xbox Series X → игры напрямую (минимальный пинг)
- Discord на ПК/смартфоне → через VLESS
- YouTube на Smart TV → через VLESS

```bash
# В конфиге Podkop добавить прямой маршрут для игровых серверов Valve
# Automatic — sing-box читает geosite:gfw и routing-ru автоматически
MODE=selective
EXTRA_DIRECT=domain:steamserver.net,domain:cm.steampowered.com
```

---

## ❓ FAQ

### Безопасно ли менять регион в Steam через VLESS Reality?

Да. VLESS Reality предоставляет индивидуальный IP-адрес нужной страны. В отличие от публичных VPN, ваш IP не помечен как «VPN/Datacenter» в базах Steam, что исключает бан аккаунта.

### Что если пинг в Discord всё равно высокий?

Discord автоматически выбирает ближайший голосовой сервер. Если вы подключены через VPN-сервер в Нидерландах, Discord выберет Amsterdam сервер — это нормально и даже лучше для голоса.

### Работает ли Split Tunneling на мобильном интернете?

Да — v2rayNG и Hiddify поддерживают Split Tunneling на Android. На iOS — через настройки маршрутизации в Streisand/Shadowrocket.

---

🎯 Тестовый ключ для геймеров: [@space_tunnel_bot](https://t.me/space_tunnel_bot?start=VC_GAMING) → промокод `VC_GAMING` → 3 дня Split Tunneling бесплатно

📖 [Вернуться к основному README](../README.md)
