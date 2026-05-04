#!/bin/bash
set -euo pipefail
cd /app
exec ./venv/bin/python manage.py runserver 0.0.0.0:8080
