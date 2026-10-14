#!/usr/bin/env bash
# Pre-flight проверки окружения перед деплоем

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/validator.sh"
source "$SCRIPT_DIR/lib/colors.sh"

declare -i ERRORS=0
declare -i WARNINGS=0

# Проверка дискового пространства
check_disk() {
    local threshold="${1:-80}"
    print_info "Проверка дискового пространства (порог: ${threshold}%)"
    
    while read -r usage mount; do
        usage_int=${usage%\%}
        if (( usage_int >= threshold )); then
            print_error "  $mount: ${usage} использования"
            ((ERRORS++))
        elif (( usage_int >= threshold - 10 )); then
            print_warning "  $mount: ${usage} использования"
            ((WARNINGS++))
        else
            print_success "  $mount: ${usage}"
        fi
    done < <(df -h --output=pcent,target | tail -n +2 | grep -vE '^/dev/loop|^tmpfs')
}

# Проверка оперативной памяти
check_memory() {
    local threshold="${1:-90}"
    print_info "Проверка оперативной памяти (порог: ${threshold}%)"
    
    local total used percent
    read -r total used _ _ _ _ < <(free -m | awk '/^Mem:/ {print $2, $3, $4, $5, $6, $7}')
    percent=$(( used * 100 / total ))
    
    if (( percent >= threshold )); then
        print_error "  Используется: ${used}MB / ${total}MB (${percent}%)"
        ((ERRORS++))
    else
        print_success "  Используется: ${used}MB / ${total}MB (${percent}%)"
    fi
}

# Проверка открытых портов
check_ports() {
    local ports=("$@")
    print_info "Проверка портов: ${ports[*]}"
    
    for port in "${ports[@]}"; do
        if ss -tln | grep -q ":${port} "; then
            print_error "  Порт $port уже занят"
            ((ERRORS++))
        else
            print_success "  Порт $port свободен"
        fi
    done
}

# Проверка необходимых команд
check_commands() {
    local cmds=("$@")
    print_info "Проверка необходимых утилит"
    
    for cmd in "${cmds[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            print_success "  $cmd: $(command -v "$cmd")"
        else
            print_error "  $cmd: НЕ УСТАНОВЛЕН"
            ((ERRORS++))
        fi
    done
}

# Использование
usage() {
    cat <<EOF
Использование: $0 --checks <check1,check2,...> [--config <file>]

Доступные проверки:
  disk[,threshold]    - Дисковое пространство (порог %)
  memory[,threshold]  - Оперативная память (порог %)
  ports,<p1:p2:...>   - Свободные порты
  commands,<c1:c2:...> - Наличие утилит

Пример:
  $0 --checks disk:85,memory,ports:80:443,commands:docker:git
EOF
}

# Парсинг аргументов
CHECKS=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --checks) CHECKS="$2"; shift 2 ;;
        --help)   usage; exit 0 ;;
        *)        shift ;;
    esac
done

[[ -z "$CHECKS" ]] && { usage; exit 1; }

print_header "Pre-flight Check"

IFS=',' read -ra check_array <<< "$CHECKS"
for check in "${check_array[@]}"; do
    IFS=':' read -ra parts <<< "$check"
    check_name="${parts[0]}"
    
    case "$check_name" in
        disk)     check_disk "${parts[1]:-80}" ;;
        memory)   check_memory "${parts[1]:-90}" ;;
        ports)    IFS=':' read -ra ports <<< "${parts[1]}"; check_ports "${ports[@]}" ;;
        commands) IFS=':' read -ra cmds <<< "${parts[1]}"; check_commands "${cmds[@]}" ;;
        *)        log_warn "Неизвестная проверка: $check_name" ;;
    esac
done

print_header "Результат"
if (( ERRORS > 0 )); then
    print_error "Обнаружено ошибок: $ERRORS, предупреждений: $WARNINGS"
    exit 1
elif (( WARNINGS > 0 )); then
    print_warning "Предупреждений: $WARNINGS"
    exit 0
else
    print_success "Все проверки пройдены"
    exit 0
fi