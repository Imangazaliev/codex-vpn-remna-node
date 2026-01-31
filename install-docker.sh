#!/bin/bash

set -euo pipefail

have_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "🔍 Проверяем Docker..."

if have_cmd docker; then
  echo "✅ Docker уже установлен: $(docker --version)"
else
  echo "🚀 Docker не найден — устанавливаем через get.docker.com..."
  wget -qO- https://get.docker.com | sudo bash
  echo "✅ Docker установлен: $(docker --version)"
fi

