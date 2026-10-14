#!/usr/bin/env bash
# Библиотека логирования для bash-infra-toolkit

# Уровни логирования
declare -A LOG_LEVELS=( [DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 )
CURRENT_LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_FILE="${LOG_DIR:-/var/log/toolkit}/toolkit.log"

# Инициализация директории логов
_init_log_dir() {
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    [[ -d "$log_dir" ]] || mkdir -p "$log_dir" 2>/dev/null || true
}

# Основная функция логирования
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Проверка уровня
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$CURRENT_LOG_LEVEL]} ]]; then
        local formatted="[$timestamp] [$level] $message"
        echo "$formatted" >> "$LOG_FILE" 2>/dev/null || true
        
        # Цветной вывод в консоль
        case "$level" in
            INFO)  echo -e "\033[0;32m$formatted\033[0m" ;;
            WARN)  echo -e "\033[1;33m$formatted\033[0m" ;;
            ERROR) echo -e "\033[0;31m$formatted\033[0m" >&2 ;;
            *)     echo "$formatted" ;;
        esac
    fi
}

log_info()  { log INFO "$@"; }
log_warn()  { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_debug() { log DEBUG "$@"; }

_init_log_dir