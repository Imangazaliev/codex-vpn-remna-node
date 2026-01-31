#!/bin/bash
set -e

SWAPFILE="/swapfile"
SWAPSIZE="2G"
FSTAB_LINE="/swapfile none swap sw 0 0"
SYSCTL_CONF="/etc/sysctl.conf"

echo "🔍 Проверяем swap..."

if swapon --show | grep -q "$SWAPFILE"; then
  echo "✅ Swap уже существует и активен"
else
  if [ -f "$SWAPFILE" ]; then
    echo "⚠️ Swap-файл существует, но не активен. Активируем..."
    sudo swapon "$SWAPFILE"
  else
    echo "🚀 Swap не найден. Создаём swap (${SWAPSIZE})..."
    sudo fallocate -l "$SWAPSIZE" "$SWAPFILE"
    sudo chmod 600 "$SWAPFILE"
    sudo mkswap "$SWAPFILE"
    sudo swapon "$SWAPFILE"
  fi
fi

echo "📌 Текущее состояние swap:"
swapon --show

echo "🧾 Проверяем /etc/fstab..."

if grep -q "^/swapfile" /etc/fstab; then
  echo "✅ Запись swap уже есть в /etc/fstab"
else
  echo "🛡️ Делаем бэкап /etc/fstab → /etc/fstab.bak"
  sudo cp /etc/fstab /etc/fstab.bak
  echo "➕ Добавляем swap в /etc/fstab"
  echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
fi

echo "⚙️ Применяем sysctl (runtime)..."
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50

echo "🧠 Проверяем persistent sysctl в $SYSCTL_CONF..."

if grep -q "^# swap settings" "$SYSCTL_CONF"; then
  echo "✅ Swap-блок уже есть в sysctl.conf"
else
  echo "➕ Добавляем swap-настройки в sysctl.conf"
  sudo tee -a "$SYSCTL_CONF" > /dev/null << 'EOL'

# swap settings
vm.swappiness=10
vm.vfs_cache_pressure=50
EOL
fi

echo "🔄 Перезагружаем sysctl из конфига..."
sudo sysctl -p

echo "📊 Финальная проверка:"
df -h
swapon --show
sysctl vm.swappiness vm.vfs_cache_pressure

echo "🎉 Готово — swap создан и настроен!"

