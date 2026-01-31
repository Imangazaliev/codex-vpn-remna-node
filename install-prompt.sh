#!/bin/bash
set -euo pipefail

BASHRC="$HOME/.bashrc"
MARKER="@codex-"

if grep -Fq "$MARKER" "$BASHRC"; then
  echo "✅ PS1-блок уже есть в $BASHRC — ничего не делаем."
else
  read -p "Введите суффикс для prompt: " PROMPT_SUFFIX

  BLOCK=$(cat <<'EOL'
###

PS1='\[\033[01;32m\]\u@codex-${PROMPT_SUFFIX}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOL
)

  echo "➕ Добавляем PS1-блок в $BASHRC"
  printf "\n%s\n" "$BLOCK" >> "$BASHRC"
fi

echo "ℹ️  Чтобы применить обновленный prompt: source ~/.bashrc"

