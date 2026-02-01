#!/usr/bin/env bash

set -euo pipefail

CODEX_PROXY_HOST="codex-proxy.ru"
REPO_SSH="git@github.com:Imangazaliev/codex-vpn-remna-node.git"
REPO_DIR="codex-vpn-remna-node"

echo "👤 Пользователь SSH для codex-proxy (по умолчанию: ubuntu):"
read -r CODEX_PROXY_USER

CODEX_PROXY_USER="${CODEX_PROXY_USER:-ubuntu}"

echo "🌐 IP или hostname целевого сервера:"
read -r TARGET_HOST

if [[ -z "${TARGET_HOST}" ]]; then
  echo "❌ Ошибка: адрес целевого сервера не указан"
  exit 1
fi

echo "👤 Пользователь SSH целевого сервера (по умолчанию: root):"
read -r TARGET_USER

TARGET_USER="${TARGET_USER:-root}"
CODEX_REMOTE="${CODEX_PROXY_USER}@${CODEX_PROXY_HOST}"

echo "🚀 Подключаемся к codex-proxy и настраиваем целевой сервер…"
ssh -o StrictHostKeyChecking=accept-new "${CODEX_REMOTE}" bash -s -- \
  "${TARGET_USER}" "${TARGET_HOST}" "${REPO_SSH}" "${REPO_DIR}" <<'REMOTE'
set -euo pipefail

TARGET_USER="$1"
TARGET_HOST="$2"
REPO_SSH="$3"
REPO_DIR="$4"

TARGET_REMOTE="${TARGET_USER}@${TARGET_HOST}"

SSH_ID_RSA="${HOME}/.ssh/id_rsa"
SSH_ID_RSA_PUB="${HOME}/.ssh/id_rsa.pub"

echo "🔑 Проверяем наличие SSH-ключей на codex-proxy…"

if [[ ! -f "${SSH_ID_RSA}" ]]; then
  echo "❌ Не найден файл ${SSH_ID_RSA} на codex-proxy"
  exit 1
fi

if [[ ! -f "${SSH_ID_RSA_PUB}" ]]; then
  echo "❌ Не найден файл ${SSH_ID_RSA_PUB} на codex-proxy"
  exit 1
fi

echo "🔌 Проверяем доступность целевого сервера по SSH…"
ssh -o StrictHostKeyChecking=accept-new "${TARGET_REMOTE}" \
  "echo '✅ Подключение успешно:' \$(hostname) '(пользователь:' \$(whoami) ')'"

echo "📁 Создаём ~/.ssh на целевом сервере…"
ssh "${TARGET_REMOTE}" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

echo "📤 Копируем SSH-ключи на целевой сервер…"
scp -p "${SSH_ID_RSA}" "${TARGET_REMOTE}:~/.ssh/id_rsa"
scp -p "${SSH_ID_RSA_PUB}" "${TARGET_REMOTE}:~/.ssh/id_rsa.pub"

echo "🔒 Выставляем корректные права на ключи…"
ssh "${TARGET_REMOTE}" "chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub"

echo "🐙 Добавляем github.com в known_hosts (без интерактива)…"
ssh "${TARGET_REMOTE}" \
  "ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null && chmod 644 ~/.ssh/known_hosts"

echo "📦 Клонируем репозиторий (или обновляем, если уже есть)…"
ssh "${TARGET_REMOTE}" "
  set -euo pipefail
  if [[ -d '${REPO_DIR}/.git' ]]; then
    cd '${REPO_DIR}'
    git fetch --all --prune
    git pull --ff-only
  else
    git clone '${REPO_SSH}' '${REPO_DIR}'
    cd '${REPO_DIR}'
  fi
"

echo "⚙️ Запускаем configure-node.sh…"
ssh "${TARGET_REMOTE}" "
  set -euo pipefail
  cd '${REPO_DIR}'
  chmod +x ./configure-node.sh
  ./configure-node.sh
"

echo "🎉 Готово! Узел успешно настроен."

