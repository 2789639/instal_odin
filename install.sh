#!/bin/bash

set -e

# === Ввод данных ===
echo "Введите IP или домен сервера (например, 5.188.83.180):"
read -r ODIN_HOST

# === Git config ===
git config --global user.name "dbelyaev"
git config --global user.email "2789639@gmail.com"

# === Обновление системы ===
echo -e "\n>>> Обновление apt и установка зависимостей..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ca-certificates gnupg lsb-release python3 python3-pip

# === Docker ===
echo -e "\n>>> Установка Docker и Docker Compose..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
  echo "Пользователь добавлен в группу docker. Перезайдите в систему для применения изменений."
fi

if ! command -v docker-compose &> /dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# === Создание общей папки ===
echo -e "\n>>> Создание общей папки /opt/odin-shared"
sudo mkdir -p /opt/odin-shared
sudo chown "$USER":"$USER" /opt/odin-shared

# === Создание необходимых директорий ===
echo -e "\n>>> Создание структуры проекта..."
mkdir -p nginx n8n

# === Создание конфигурации nginx ===
cat > nginx/default.conf << EOF
server {
    listen 80;
    server_name $ODIN_HOST;

    location /n8n/ {
        proxy_pass http://n8n:5678/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /studio/ {
        proxy_pass http://studio:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /ollama/ {
        proxy_pass http://ollama:11434/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# === Создание конфигурации n8n ===
cat > n8n/docker.env << EOF
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=admin123
WEBHOOK_URL=http://$ODIN_HOST/n8n/
N8N_HOST=$ODIN_HOST
N8N_PORT=5678
N8N_PROTOCOL=http
EOF

# === Переменные окружения ===
echo "ODIN_HOST=$ODIN_HOST" > .env

# === Готово ===
echo -e "\n>>> Готово! Теперь запустите:"
echo "docker-compose up -d"
echo -e "\nСервисы будут доступны по адресам:"
echo "- N8N: http://$ODIN_HOST/n8n/"
echo "- Supabase Studio: http://$ODIN_HOST/studio/"
echo "- Ollama: http://$ODIN_HOST/ollama/"