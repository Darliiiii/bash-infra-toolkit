#!/usr/bin/env bash
# Анализ системных метрик и логов

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/colors.sh"

# Анализ auth-логов на предмет брутфорса
analyze_auth_failures() {
    local log_file="${1:-/var/log/secure}"
    print_info "Анализ неудачных попыток входа в $log_file"
    
    if [[ ! -f "$log_file" ]]; then
        log_warn "Файл $log_file не найден"
        return 0
    fi
    
    echo -e "${BOLD}Топ-10 IP-адресов с неудачными попытками:${NC}"
    awk '/Invalid user|Failed password/ {print $(NF-3)}' "$log_file" 2>/dev/null | \
        sort | uniq -c | sort -rn | head -10 | \
        while read -r count ip; do
            if (( count > 100 )); then
                print_error "  $ip: $count попыток"
            elif (( count > 20 )); then
                print_warning "  $ip: $count попыток"
            else
                echo "  $ip: $count попыток"
            fi
        done
}

# Анализ размера логов
analyze_log_sizes() {
    print_info "Анализ размера лог-файлов в /var/log"
    
    echo -e "${BOLD}Топ-10 самых больших лог-файлов:${NC}"
    find /var/log -type f -name "*.log" -exec du -h {} + 2>/dev/null | \
        sort -rh | head -10 | \
        while read -r size file; do
            local size_mb
            size_mb=$(echo "$size" | sed 's/[A-Z]//')
            if (( $(echo "$size_mb > 100" | bc -l) )); then
                print_warning "  $file: $size"
            else
                echo "  $file: $size"
            fi
        done
}

# Статистика процессов
analyze_processes() {
    print_info "Статистика процессов"
    
    echo -e "${BOLD}Топ-5 процессов по потреблению CPU:${NC}"
    ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -6 | column -t
    
    echo -e "\n${BOLD}Топ-5 процессов по потреблению RAM:${NC}"
    ps -eo pid,pcpu,pmem,comm --sort=-pmem | head -6 | column -t
}

# Расчёт средних значений (через bc для дробных)
calculate_stats() {
    local -a values=("$@")
    local sum=0
    local count=${#values[@]}
    local min=${values[0]}
    local max=${values[0]}
    
    for v in "${values[@]}"; do
        sum=$(echo "$sum + $v" | bc -l)
        (( $(echo "$v < $min" | bc -l) )) && min=$v
        (( $(echo "$v > $max" | bc -l) )) && max=$v
    done
    
    local avg
    avg=$(echo "scale=2; $sum / $count" | bc -l)
    
    echo "Count: $count | Min: $min | Max: $max | Avg: $avg"
}

# Использование
case "${1:-help}" in
    auth)     analyze_auth_failures "${2:-/var/log/secure}" ;;
    sizes)    analyze_log_sizes ;;
    procs)    analyze_processes ;;
    stats)    shift; calculate_stats "$@" ;;
    all)      
        print_header "Комплексный анализ системы"
        analyze_auth_failures
        echo
        analyze_log_sizes
        echo
        analyze_processes
        ;;
    *)
        cat <<EOF
Использование: $0 <command>

Команды:
  auth [logfile]  - Анализ неудачных попыток входа
  sizes           - Анализ размера логов
  procs           - Статистика процессов
  stats <nums>    - Расчёт статистики (min/max/avg)
  all             - Комплексный анализ

Пример:
  sudo $0 all
  $0 stats 10 20 30 40 50
EOF
        ;;
esac