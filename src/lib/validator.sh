#!/usr/bin/env bash
# Библиотека валидации входных данных

# Проверка существования файла
require_file() {
    local file="$1"
    local desc="${2:-файл}"
    if [[ ! -f "$file" ]]; then
        echo "Файл не найден: $file" >&2
        return 1
    fi
}

# Проверка существования директории
require_dir() {
    local dir="$1"
    local desc="${2:-директория}"
    if [[ ! -d "$dir" ]]; then
        echo "Директория не найдена: $dir" >&2
        return 1
    fi
}

# Проверка прав root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Требуются права root" >&2
        return 1
    fi
}

# Проверка существования команды
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "Не установлена утилита: $cmd" >&2
        return 1
    fi
}

# Валидация email (базовая)
validate_email() {
    local email="$1"
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

# Валидация имени пользователя Linux
validate_username() {
    local username="$1"
    [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] && [[ ${#username} -le 32 ]]
}