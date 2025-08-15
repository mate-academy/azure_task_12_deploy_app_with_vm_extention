#!/usr/bin/env bash
set -euxo pipefail

# GitHub username передається через PowerShell
GITHUB_USER="${GITHUB_USER:-Yevgene-DP}"
REPO="https://github.com/${GITHUB_USER}/azure_task_12_deploy_app_with_vm_extention.git"
APP_DIR="/opt/azapp"
PORT=8080

# 1) Пакети
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git nginx

# 2) Клон репозиторію
rm -rf "$APP_DIR"
git clone --depth 1 "$REPO" "$APP_DIR"

# 3) Якщо є папка 'site' або 'public' — віддавати її; інакше — корінь репозиторію
if [ -d "$APP_DIR/site" ]; then
  ROOT_DIR="$APP_DIR/site"
elif [ -d "$APP_DIR/public" ]; then
  ROOT_DIR="$APP_DIR/public"
else
  ROOT_DIR="$APP_DIR"
fi

# 4) Nginx на 8080
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
