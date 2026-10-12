#!/bin/bash
set -e

# Install required system packages
apt-get update -yq
apt-get install -yq git python3-pip python3-venv dos2unix

# Clone your GitHub fork
REPO_URL="https://github.com/Pugach-Nazar/azure_task_12_deploy_app_with_vm_extention.git"
REPO_DIR="/tmp/azure_task_12_deploy_app_with_vm_extention"
APP_DIR="/app"

rm -rf "$REPO_DIR"
git clone --branch main "$REPO_URL" "$REPO_DIR"

# Copy application files to /app
mkdir -p "$APP_DIR"
cp -r "$REPO_DIR/app/." "$APP_DIR/"

# Convert Windows CRLF line endings to Linux LF
find "$APP_DIR" -type f \( -name "*.sh" -o -name "*.service" \) \
    -exec dos2unix {} \;

# Create virtual environment
python3 -m venv "$APP_DIR/.venv"

# Install Python dependencies
cd "$APP_DIR"
"$APP_DIR/.venv/bin/pip" install -r requirements.txt

# Install and start the systemd service
install -m 644 "$APP_DIR/todoapp.service" \
    /etc/systemd/system/todoapp.service

systemctl daemon-reload
systemctl enable --now todoapp.service