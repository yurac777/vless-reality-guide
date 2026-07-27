#!/bin/bash
# =============================================================
# VLESS Reality Auto-Installer (Ubuntu 22.04 / Debian 12)
# Автоматическая установка XRay Core + Reality на VPS
# =============================================================
# Использование:
#   bash install.sh
#
# Что делает скрипт:
#   1. Устанавливает XRay Core
#   2. Генерирует UUID, X25519 ключи, Short ID
#   3. Записывает config.json
#   4. Настраивает systemd сервис
#   5. Открывает порт 443 в UFW
#   6. Выводит строку подключения vless://...
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Проверка root
[[ $EUID -ne 0 ]] && error "Запустите скрипт от root: sudo bash install.sh"

# Определение внешнего IP
SERVER_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me)
[[ -z "$SERVER_IP" ]] && error "Не удалось определить внешний IP сервера"
log "Сервер: $SERVER_IP"

# Целевой домен для Reality (маскировка)
DEST_HOST="www.apple.com"
DEST_SNI="www.apple.com"

header "1. Установка XRay Core"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
log "XRay Core установлен: $(xray version | head -1)"

header "2. Генерация ключей"
UUID=$(xray uuid)
log "UUID: $UUID"

X25519=$(xray x25519)
PRIVATE_KEY=$(echo "$X25519" | grep "Private key" | awk '{print $NF}')
PUBLIC_KEY=$(echo "$X25519" | grep "Public key" | awk '{print $NF}')
log "Private Key: $PRIVATE_KEY"
log "Public Key:  $PUBLIC_KEY"

SHORT_ID=$(openssl rand -hex 4)
log "Short ID: $SHORT_ID"

header "3. Запись конфигурации"
mkdir -p /usr/local/etc/xray

cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${DEST_HOST}:443",
          "xver": 0,
          "serverNames": ["${DEST_SNI}"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
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
EOF
log "config.json записан"

header "4. Настройка systemd"
systemctl enable xray
systemctl restart xray
sleep 2
if systemctl is-active --quiet xray; then
    log "XRay сервис запущен"
else
    error "XRay не запустился. Проверьте: journalctl -u xray -n 50"
fi

header "5. Открытие порта 443"
if command -v ufw &>/dev/null; then
    ufw allow 443/tcp
    log "UFW: порт 443 открыт"
fi

header "6. Результат"
VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${DEST_SNI}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp#VLESS-Reality"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ VLESS Reality установлен успешно!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Данные для клиента:${NC}"
echo "  Сервер:      $SERVER_IP"
echo "  Порт:        443"
echo "  UUID:        $UUID"
echo "  Public Key:  $PUBLIC_KEY"
echo "  Short ID:    $SHORT_ID"
echo "  SNI:         $DEST_SNI"
echo "  Flow:        xtls-rprx-vision"
echo "  Security:    reality"
echo "  Fingerprint: chrome"
echo ""
echo -e "${YELLOW}🔗 Ссылка для импорта в клиент (vless://...):${NC}"
echo ""
echo "$VLESS_LINK"
echo ""
echo -e "${YELLOW}📱 QR-код (отсканируйте в v2rayNG / Streisand):${NC}"
qrencode -t ANSIUTF8 "$VLESS_LINK" 2>/dev/null || echo "  (установите qrencode для QR: apt install qrencode)"
echo ""
echo -e "${GREEN}📖 Гайд по настройке клиентов:${NC}"
echo "  https://github.com/yurac777/vless-reality-guide"
echo ""
