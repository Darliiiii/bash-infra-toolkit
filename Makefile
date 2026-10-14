.PHONY: install uninstall test lint clean

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/bash-infra-toolkit

install:
	@echo "Установка bash-infra-toolkit..."
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(LIBDIR)/lib
	install -m 755 src/*.sh $(DESTDIR)$(BINDIR)/
	install -m 644 src/lib/*.sh $(DESTDIR)$(LIBDIR)/lib/
	@echo "Установка завершена"

uninstall:
	@echo "Удаление bash-infra-toolkit..."
	rm -f $(DESTDIR)$(BINDIR)/user_manager.sh
	rm -f $(DESTDIR)$(BINDIR)/preflight_check.sh
	rm -f $(DESTDIR)$(BINDIR)/log_analyzer.sh
	rm -f $(DESTDIR)$(BINDIR)/secure_cli.sh
	rm -rf $(DESTDIR)$(LIBDIR)
	@echo "Удаление завершено"

test:
	@echo "Запуск тестов..."
	bash tests/test_user_manager.sh

lint:
	@echo "Проверка стиля кода..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "Установите shellcheck"; exit 1; }
	shellcheck src/*.sh src/lib/*.sh

clean:
	@echo "Очистка..."
	rm -f logs/*.log
	find . -name "*.tmp" -delete