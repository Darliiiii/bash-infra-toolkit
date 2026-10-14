#!/usr/bin/env bash
# Управление пользователями из CSV-файла
# Формат CSV: username,fullname,group1:group2,email

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/validator.sh"
source "$SCRIPT_DIR/lib/colors.sh"

# Обработка сигналов - очистка временных файлов
cleanup() {
    local exit_code=$?
    [[ -n "${TEMP_FILE:-}" ]] && rm -f "$TEMP_FILE"
    log_info "Скрипт завершён с кодом $exit_code"
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Использование
usage() {
    cat <<EOF
Использование: $0 --action <create|delete|list> --file <csv_file>

Опции:
  --action    Действие: create, delete, list
  --file      Путь к CSV-файлу
  --dry-run   Симуляция без реальных изменений
  --help      Показать эту справку

Пример:
  sudo $0 --action create --file users.csv
EOF
}

# Генерация временного пароля
generate_password() {
    openssl rand -base64 12 | tr -d '/+=' | head -c 12
}

# Создание пользователя
create_user() {
    local username="$1"
    local fullname="$2"
    local groups="$3"
    local email="$4"
    local dry_run="$5"
    
    if id "$username" &>/dev/null; then
        log_warn "Пользователь $username уже существует, пропускаю"
        return 0
    fi
    
    local password
    password=$(generate_password)
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY-RUN] Создан пользователь: $username ($fullname)"
        return 0
    fi
    
    useradd -m -c "$fullname" -s /bin/bash "$username"
    
    if [[ -n "$groups" ]]; then
        IFS=':' read -ra group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            usermod -aG "$group" "$username" 2>/dev/null || \
                log_warn "Группа $group не существует"
        done
    fi
    
    echo "$username:$password" | chpasswd
    log_info "Создан пользователь: $username (пароль сохранён в /root/.new_users)"
    echo "$username:$password:$email" >> /root/.new_users
}

# Удаление пользователя
delete_user() {
    local username="$1"
    local dry_run="$2"
    
    if ! id "$username" &>/dev/null; then
        log_warn "Пользователь $username не существует"
        return 0
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY-RUN] Удалён пользователь: $username"
        return 0
    fi
    
    userdel -r "$username" 2>/dev/null || userdel "$username"
    log_info "Удалён пользователь: $username"
}

# Парсинг аргументов
ACTION=""
CSV_FILE=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --action)  ACTION="$2"; shift 2 ;;
        --file)    CSV_FILE="$2"; shift 2 ;;
        --dry-run) DRY_RUN="true"; shift ;;
        --help)    usage; exit 0 ;;
        *)         echo "Неизвестная опция: $1"; usage; exit 1 ;;
    esac
done

# Валидация
require_root
require_command useradd
require_file "$CSV_FILE" "CSV-файл"

if [[ -z "$ACTION" ]]; then
    print_error "Не указано действие"
    usage
    exit 1
fi

# Инициализация файла паролей
if [[ "$ACTION" == "create" && "$DRY_RUN" != "true" ]]; then
    : > /root/.new_users
    chmod 600 /root/.new_users
fi

print_header "User Manager: $ACTION"

# Обработка CSV
while IFS=',' read -r username fullname groups email; do
    [[ "$username" =~ ^#.*$ ]] && continue  # Пропуск комментариев
    [[ -z "$username" ]] && continue
    
    # Валидация
    if ! validate_username "$username"; then
        log_error "Некорректное имя пользователя: $username"
        continue
    fi
    
    case "$ACTION" in
        create) create_user "$username" "$fullname" "$groups" "$email" "$DRY_RUN" ;;
        delete) delete_user "$username" "$DRY_RUN" ;;
        list)   id "$username" &>/dev/null && echo "[OK] $username" || echo "[FAIL] $username (отсутствует)" ;;
        *)      log_error "Неизвестное действие: $ACTION"; exit 1 ;;
    esac
done < "$CSV_FILE"

print_success "Операция завершена"