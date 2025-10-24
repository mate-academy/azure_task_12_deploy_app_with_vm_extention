#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# 1) Пакети
apt-get update -yq
apt-get install -yq git python3-pip

# 2) Директория додатку
mkdir -p /app

# 3) Клон твоєї репи у /tmp
TMP_DIR=/tmp/todoapp
rm -rf "$TMP_DIR"
git clone --depth 1 https://github.com/VitaliySemeniv/azure_task_12_deploy_app_with_vm_extention.git "$TMP_DIR"

# 4) Копіюємо файли у /app
cp -r "$TMP_DIR/app/"* /app

# 5) Встановлюємо залежності (без --break-system-packages)
python3 -m pip install -r /app/requirements.txt

# 6) systemd сервіс
cp /app/todoapp.service /etc/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp