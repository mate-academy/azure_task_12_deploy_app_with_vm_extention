#!/bin/bash

# 1. Оновлення та встановлення git (важливо для клонування)
apt-get update -yq
apt-get install python3-pip git -yq

# 2. Видаляємо стару папку, якщо вона є, і клонуємо репо заново
rm -rf /tmp/my-repo
git clone https://github.com/TongobashV/azure_task_12_deploy_app_with_vm_extention.git /tmp/my-repo

# 3. Створюємо папку додатка
mkdir -p /app

# 4. Копіюємо файли з ТИМЧАСОВОЇ папки, куди ми щойно клонували репо
cp -r /tmp/my-repo/app/* /app/

# 5. Налаштування сервісу
if [ -f "/app/todoapp.service" ]; then
    mv /app/todoapp.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable todoapp
    systemctl start todoapp
    echo "Application started successfully!"
else
    echo "Error: todoapp.service not found in /app"
    exit 1
fi