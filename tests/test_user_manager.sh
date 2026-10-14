#!/usr/bin/env bash
# Простые тесты для user_manager.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Запуск тестов..."

# Тест 1: Проверка наличия всех скриптов
echo -n "Тест 1: Наличие скриптов... "
for script in user_manager.sh preflight_check.sh log_analyzer.sh secure_cli.sh; do
    [[ -f "$PROJECT_DIR/src/$script" ]] || { echo "FAIL: $script не найден"; exit 1; }
done
echo "OK"

# Тест 2: Проверка библиотек
echo -n "Тест 2: Наличие библиотек... "
for lib in logger.sh validator.sh colors.sh; do
    [[ -f "$PROJECT_DIR/src/lib/$lib" ]] || { echo "FAIL: $lib не найдена"; exit 1; }
done
echo "OK"

# Тест 3: Проверка синтаксиса bash
echo -n "Тест 3: Синтаксис bash... "
for script in "$PROJECT_DIR/src/"*.sh "$PROJECT_DIR/src/lib/"*.sh; do
    bash -n "$script" || { echo "FAIL: синтаксис $script"; exit 1; }
done
echo "OK"

echo "Все тесты пройдены"