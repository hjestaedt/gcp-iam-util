# gcp iam util Makefile

INSTALL_DIR ?= $(HOME)/bin
SCRIPT_NAME = gcp-iam-util

MAIN_SCRIPT = gcp-iam-util
LIB_DIR = lib
LIB_FILES = $(wildcard $(LIB_DIR)/*.sh $(LIB_DIR)/*/*.sh)

.PHONY: install uninstall clean test check show-config

install:
	@echo "installing $(SCRIPT_NAME) to $(INSTALL_DIR)..."
	@mkdir -p "$(INSTALL_DIR)"
	@mkdir -p "$(INSTALL_DIR)/$(SCRIPT_NAME).d/commands"
	@cp "$(MAIN_SCRIPT)" "$(INSTALL_DIR)/$(SCRIPT_NAME).d/"
	@cp -r "$(LIB_DIR)"/* "$(INSTALL_DIR)/$(SCRIPT_NAME).d/"
	@chmod +x "$(INSTALL_DIR)/$(SCRIPT_NAME).d/$(MAIN_SCRIPT)"
	@ln -sf "$(SCRIPT_NAME).d/$(MAIN_SCRIPT)" "$(INSTALL_DIR)/$(SCRIPT_NAME)"
	@echo "installation complete!"

uninstall:
	@echo "uninstalling $(SCRIPT_NAME) from $(INSTALL_DIR)..."
	@rm -f "$(INSTALL_DIR)/$(MAIN_SCRIPT)"
	@rm -rf "$(INSTALL_DIR)/$(SCRIPT_NAME).d"
	@echo "uninstallation complete!"

clean:
	@echo "cleaning up temporary files..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@echo "clean complete!"

check:
	@echo "running shellcheck on all scripts..."
	@shellcheck "$(MAIN_SCRIPT)" $(LIB_FILES)
	@echo "all checks passed!"

test:
	@echo "running comprehensive test suite..."
	@if [ -f test-gcp-iam-util ]; then \
		./test-gcp-iam-util "./$(MAIN_SCRIPT)"; \
	else \
		echo "warning: test-gcp-iam-util not found, skipping comprehensive tests"; \
	fi

show-config:
	@echo "configuration:"
	@echo "  INSTALL_DIR: $(INSTALL_DIR)"
	@echo "  SCRIPT_NAME: $(SCRIPT_NAME)"
	@echo "  MAIN_SCRIPT: $(MAIN_SCRIPT)"
	@echo "  LIB_FILES: $(LIB_FILES)" 