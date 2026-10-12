#! /bin/bash

cd /app

/app/.venv/bin/python manage.py migrate

exec /app/.venv/bin/python manage.py runserver 0.0.0.0:8080