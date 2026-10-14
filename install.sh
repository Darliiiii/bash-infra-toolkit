#!/usr/bin/env bash
set -euo pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Проверка root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} Скрипт требует прав root"
   exit 1
fi

echo -e "${GREEN}[INFO]${NC} Установка bash-infra-toolkit..."

# Копирование
install -d /usr/local/lib/bash-infra-toolkit/lib
install -m 755 src/*.sh /usr/local/bin/
install -m 644 src/lib/*.sh /usr/local/lib/bash-infra-toolkit/lib/

echo -e "${GREEN}[OK]${NC} Установка завершена"
echo -e "${YELLOW}[!]${NC} Примеры конфигов в config/"