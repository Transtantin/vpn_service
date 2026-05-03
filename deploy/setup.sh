#!/bin/bash
# Скрипт разворачивает FastAPI сервер на чистом Ubuntu (LXC или VM)
# Запускать от root: bash setup.sh

set -e  # остановиться при любой ошибке

echo "=== Обновляем систему ==="
apt update && apt upgrade -y

echo "=== Устанавливаем зависимости ==="
apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git

echo "=== Клонируем репозиторий ==="
cd /opt
git clone https://github.com/Transtantin/vpn_service.git
cd vpn_service

echo "=== Создаём виртуальное окружение и устанавливаем пакеты ==="
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

echo "=== Копируем systemd сервис ==="
cp deploy/vpn-api.service /etc/systemd/system/vpn-api.service
systemctl daemon-reload
systemctl enable vpn-api
systemctl start vpn-api

echo "=== Копируем конфиг nginx ==="
cp deploy/nginx.conf /etc/nginx/sites-available/vpn-api
ln -sf /etc/nginx/sites-available/vpn-api /etc/nginx/sites-enabled/vpn-api
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo ""
echo "=== Готово! ==="
echo "Теперь получи SSL сертификат:"
echo "  certbot --nginx -d ТВО_ДОМЕН"
echo ""
echo "Не забудь отредактировать /opt/vpn_service/servers.json с реальными конфигами!"
