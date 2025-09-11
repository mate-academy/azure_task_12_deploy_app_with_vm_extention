#!/bin/bash
set -ex

APP_SRC="/tmp/azure_task_12_src"
APP_DST="/app"

# ---------------------------
# Install system dependencies
# ---------------------------
apt-get update -yq
apt-get install -yq git python3-pip curl

# ---------------------------
# Clone or update repo
# ---------------------------
if [ -d "$APP_SRC/.git" ]; then
    git -C "$APP_SRC" pull
else
    rm -rf "$APP_SRC"
    git clone https://github.com/LitvinchukRoman/azure_task_12_deploy_app_with_vm_extention.git "$APP_SRC"
fi

# ---------------------------
# Copy app files
# ---------------------------
mkdir -p "$APP_DST"
cp -r "$APP_SRC/app/"* "$APP_DST/"

# ---------------------------
# Python dependencies
# ---------------------------
if [ -f "$APP_DST/requirements.txt" ]; then
    pip3 install -r "$APP_DST/requirements.txt"
fi

# ---------------------------
# Systemd service
# ---------------------------
cp "$APP_DST/todoapp.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now todoapp

# ---------------------------
# Verify service is running
# ---------------------------
systemctl is-active --quiet todoapp || { echo "❌ todoapp service is not active"; exit 1; }

# ---------------------------
# Verify app listens on port 8080
# ---------------------------
for i in {1..5}; do
    if ss -ltn | grep -q ':8080'; then
        echo "✅ App is listening on port 8080"
        exit 0
    fi
    echo "Waiting for app to start..."
    sleep 5
done

echo "❌ App did not start on port 8080"
exit 1