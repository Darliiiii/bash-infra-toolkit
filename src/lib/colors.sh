#!/usr/bin/env bash
# Цветовая палитра для терминала

# Проверка поддержки цветов
if [[ -t 1 ]] && [[ -z "$NO_COLOR" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' NC=''
fi

# Функции быстрого вывода
print_success() { echo -e "${GREEN}[OK]${NC} $*"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
print_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
print_header()  { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }