#!/bin/bash

set -e

REMNA_NODE_DIR="/opt/remnanode"
ENV_FILE="$REMNA_NODE_DIR/.env"

# Запрашиваем SECRET_KEY (ввод скрыт)
read -s -p "Введите SECRET_KEY: " SECRET_KEY
echo
read -s -p "Повторите SECRET_KEY: " SECRET_KEY_CONFIRM
echo

if [ "$SECRET_KEY" != "$SECRET_KEY_CONFIRM" ]; then
  echo "❌ SECRET_KEY не совпадают"
  exit 1
fi

echo "🔐 SECRET_KEY принят"

echo "📁 Проверяем директорию $REMNA_NODE_DIR"
mkdir -p "$REMNA_NODE_DIR"

echo "📦 Копируем docker-compose.yml"
sudo cp docker-compose.yml "$REMNA_NODE_DIR/docker-compose.yml"

echo "✍️ Записываем переменные в $ENV_FILE"
tee -a "$ENV_FILE" > /dev/null <<EOL
NODE_PORT=2222
SECRET_KEY="$SECRET_KEY"
EOL

cd "$REMNA_NODE_DIR"

docker compose pull
docker compose down
docker compose up -d

echo "✅ Готово — нода Remnawave настроена!"

