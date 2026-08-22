#!/bin/bash

cd /app
/app/.venv/bin/pip install -r requirements.txt
/app/.venv/bin/python manage.py migrate
/app/.venv/bin/python manage.py runserver 0.0.0.0:8080