#!/bin/bash

set -e

# === Ввод данных ===
echo "Введите IP или домен сервера (например, 5.188.83.180):"
read -r ODIN_HOST

# === Git config ===
git config --global user.name "dbelyaev"
git config --global user.email "2789639@gmail.com"

# === Обновление системы ===
echo "\n>>> Обновление apt и установка зависимостей..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ca-certificates gnupg lsb-release python3 python3-pip

# === Docker ===
echo "\n>>> Установка Docker и Docker Compose..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

if ! command -v docker-compose &> /dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# === Создание общей папки ===
echo "\n>>> Создание общей папки /opt/odin-shared"
sudo mkdir -p /opt/odin-shared
sudo chown "$USER":"$USER" /opt/odin-shared

# === Клонирование проекта ===
echo "\n>>> Клонирование репозитория odin-setup"
git clone https://github.com/dbelyaev/odin-setup.git || echo "(репозиторий уже существует)"
cd odin-setup

# === Переменные окружения ===
echo "ODIN_HOST=$ODIN_HOST" > .env

# === Готово ===
echo "\n>>> Готово. Теперь запусти:"
echo "cd odin-setup && docker-compose up -d"
echo "Проверь: http://$ODIN_HOST/n8n  и  http://$ODIN_HOST/studio"
