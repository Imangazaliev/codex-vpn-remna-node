
#!/usr/bin/env bash
set -euo pipefail

CODEX_PROXY_HOST="codex-proxy.ru"
REPO_SSH="git@github.com:Imangazaliev/codex-vpn-remna-node.git"
REPO_DIR="codex-vpn-remna-node"
LOCAL_ENV_FILE="./.env"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "👤 Пользователь SSH для codex-proxy (по умолчанию: ubuntu):"
read -r CODEX_PROXY_USER
CODEX_PROXY_USER="${CODEX_PROXY_USER:-ubuntu}"
CODEX_REMOTE="${CODEX_PROXY_USER}@${CODEX_PROXY_HOST}"

echo "🌐 IP или hostname целевого сервера:"
read -r TARGET_HOST
if [[ -z "${TARGET_HOST}" ]]; then
  echo "❌ Ошибка: адрес целевого сервера не указан"
  exit 1
fi

echo "👤 Пользователь SSH целевого сервера (по умолчанию: root):"
read -r TARGET_USER
TARGET_USER="${TARGET_USER:-root}"
TARGET_REMOTE="${TARGET_USER}@${TARGET_HOST}"

echo "🔌 Проверяем доступ по SSH к codex-proxy…"
ssh -o StrictHostKeyChecking=accept-new "${CODEX_REMOTE}" "echo '✅ codex-proxy доступен:' \$(hostname)"

echo "🔌 Проверяем доступ по SSH к целевому серверу…"
ssh -o StrictHostKeyChecking=accept-new "${TARGET_REMOTE}" "echo '✅ target доступен:' \$(hostname)"

echo "🔑 Копируем ключи с codex-proxy на локальную машину во временную папку…"
scp -p "${CODEX_REMOTE}:~/.ssh/id_rsa" "${TMP_DIR}/id_rsa"
scp -p "${CODEX_REMOTE}:~/.ssh/id_rsa.pub" "${TMP_DIR}/id_rsa.pub"

echo "🔒 Выставляем безопасные права на ключи локально…"
chmod 600 "${TMP_DIR}/id_rsa"
chmod 644 "${TMP_DIR}/id_rsa.pub"

echo "📁 Создаём ~/.ssh на целевом сервере…"
ssh "${TARGET_REMOTE}" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

echo "📤 Загружаем ключи на целевой сервер…"
scp -p "${TMP_DIR}/id_rsa" "${TARGET_REMOTE}:~/.ssh/id_rsa"
scp -p "${TMP_DIR}/id_rsa.pub" "${TARGET_REMOTE}:~/.ssh/id_rsa.pub"

echo "🔒 Выставляем корректные права на ключи на целевом сервере…"
ssh "${TARGET_REMOTE}" "chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub"

echo "🐙 Добавляем github.com в known_hosts на целевом сервере (без интерактива)…"
ssh "${TARGET_REMOTE}" "ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null && chmod 644 ~/.ssh/known_hosts"

echo "📦 Клонируем репозиторий на целевом сервере (или обновляем, если уже есть)…"
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

if [[ -f "${LOCAL_ENV_FILE}" ]]; then
  echo "📄 Найден локальный .env — копируем на целевой сервер…"
  scp -p "${LOCAL_ENV_FILE}" "${TARGET_REMOTE}:~/${REPO_DIR}/.env"
else
  echo "ℹ️ Локальный .env не найден — пропускаем этот шаг"
fi

echo "⚙️  Запускаем configure-node.sh на целевом сервере…"
ssh "${TARGET_REMOTE}" "
  set -euo pipefail
  cd '${REPO_DIR}'
  chmod +x ./configure-node.sh
  ./configure-node.sh
"

echo "🎉 Готово! Сервер ${TARGET_HOST} успешно настроен!"

