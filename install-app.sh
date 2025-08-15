#!/usr/bin/env bash
set -euxo pipefail

GITHUB_USER="Yevgene-DP"
REPO="https://github.com/${GITHUB_USER}/azure_task_12_deploy_app_with_vm_extention.git"
APP_DIR="/opt/azapp"
PORT=8080

# 1) Оновлення і встановлення потрібного
export DEBIAN_FRONTEND=noninteractive
apt-get clean
apt-get update -y
apt-get install -y --no-install-recommends git curl ca-certificates software-properties-common
apt-get install -y nginx

# 2) Клонування репозиторію
rm -rf "$APP_DIR"
git clone --depth 1 "$REPO" "$APP_DIR"

# 3) Визначення кореня
if [ -d "$APP_DIR/site" ]; then
  ROOT_DIR="$APP_DIR/site"
elif [ -d "$APP_DIR/public" ]; then
  ROOT_DIR="$APP_DIR/public"
else
  ROOT_DIR="$APP_DIR"
fi

# 4) Конфігурація Nginx на 8080
cat >/etc/nginx/sites-available/azapp <<EOF
server {
    listen ${PORT} default_server;
    listen [::]:${PORT} default_server;

    root ${ROOT_DIR};
    index index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/azapp /etc/nginx/sites-enabled/azapp
rm -f /etc/nginx/sites-enabled/default || true

systemctl enable nginx
systemctl restart nginx
