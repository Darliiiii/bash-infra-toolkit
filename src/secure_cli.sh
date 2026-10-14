#!/usr/bin/env bash
# Интерактивный CLI с безопасным вводом

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/validator.sh"
source "$SCRIPT_DIR/lib/colors.sh"

# Безопасный ввод с таймаутом
secure_input() {
    local prompt="$1"
    local timeout="${2:-30}"
    local hidden="${3:-false}"
    local result
    
    if [[ "$hidden" == "true" ]]; then
        read -r -s -t "$timeout" -p "$prompt" result || {
            echo ""
            log_warn "Время ожидания истекло"
            return 1
        }
        echo ""
    else
        read -r -t "$timeout" -p "$prompt" result || {
            log_warn "Время ожидания истекло"
            return 1
        }
    fi
    
    echo "$result"
}

# Основная функция
main() {
    print_header "Secure CLI Tool"
    
    # Ввод имени пользователя
    local username
    username=$(secure_input "Введите имя пользователя: " 30 false) || exit 1
    
    if ! validate_username "$username"; then
        print_error "Некорректное имя пользователя"
        exit 1
    fi
    
    # Ввод email
    local email
    email=$(secure_input "Введите email: " 30 false) || exit 1
    
    if ! validate_email "$email"; then
        print_error "Некорректный email"
        exit 1
    fi
    
    # Скрытый ввод пароля
    local password
    password=$(secure_input "Введите пароль (скрытый ввод): " 30 true) || exit 1
    
    if [[ ${#password} -lt 8 ]]; then
        print_error "Пароль слишком короткий (минимум 8 символов)"
        exit 1
    fi
    
    # Подтверждение
    local confirm
    confirm=$(secure_input "Подтвердите пароль: " 30 true) || exit 1
    
    if [[ "$password" != "$confirm" ]]; then
        print_error "Пароли не совпадают"
        exit 1
    fi
    
    # Вывод результата
    print_header "Результат"
    echo "Username: $username"
    echo "Email: $email"
    echo "Password length: ${#password} символов"
    
    log_info "Данные успешно введены для пользователя $username"
}

main "$@"