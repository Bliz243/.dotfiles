.PHONY: help install update stow unstow restow health test clean backup sync push add-tool

# Default target
.DEFAULT_GOAL := help

# Dotfiles directory
DOTFILES_DIR := $(HOME)/.dotfiles

help: ## Show this help message
	@echo ""
	@echo "🚀 Dotfiles Management"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

install: ## Full installation (Ansible + Stow)
	@echo "🚀 Running full installation..."
	@bash $(DOTFILES_DIR)/install.sh
	@bash $(DOTFILES_DIR)/scripts/stow.sh
	@echo "✨ Installation complete!"

bootstrap: ## Bootstrap from scratch (for new machines)
	@bash $(DOTFILES_DIR)/scripts/bootstrap.sh

update: ## Update all tools and configurations
	@bash $(DOTFILES_DIR)/update.sh

stow: ## Stow all dotfiles packages
	@bash $(DOTFILES_DIR)/scripts/stow.sh

unstow: ## Remove all dotfiles symlinks
	@bash $(DOTFILES_DIR)/scripts/unstow.sh

restow: ## Re-stow all packages (refresh symlinks)
	@bash $(DOTFILES_DIR)/scripts/restow.sh

health: ## Run health check
	@bash $(DOTFILES_DIR)/scripts/health-check.sh

test: ## Run all tests and validation
	@bash $(DOTFILES_DIR)/scripts/test.sh

clean: ## Clean up temporary files and caches
	@echo "🧹 Cleaning up..."
	@find $(DOTFILES_DIR) -name "*.swp" -delete
	@find $(DOTFILES_DIR) -name "*.swo" -delete
	@find $(DOTFILES_DIR) -name ".DS_Store" -delete
	@find $(DOTFILES_DIR) -name "*~" -delete
	@echo "✨ Clean complete!"

backup: ## Backup current dotfiles before changes
	@echo "💾 Creating backup..."
	@tar -czf $(HOME)/dotfiles-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz -C $(HOME) .dotfiles
	@echo "✨ Backup created at $(HOME)/dotfiles-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz"

sync: ## Pull latest changes and restow
	@echo "🔄 Syncing dotfiles from remote..."
	@cd $(DOTFILES_DIR) && git pull origin main || git pull origin master
	@bash $(DOTFILES_DIR)/scripts/restow.sh
	@echo "✨ Sync complete!"

push: ## Commit and push changes (interactive)
	@echo "📤 Pushing dotfiles to remote..."
	@cd $(DOTFILES_DIR) && git add -A
	@cd $(DOTFILES_DIR) && git status
	@echo ""
	@read -p "Commit message: " msg; \
	cd $(DOTFILES_DIR) && git commit -m "$$msg" && git push origin main || git push origin master
	@echo "✨ Changes pushed!"

add-tool: ## Add a new tool to dotfiles (usage: make add-tool TOOL=name)
	@bash $(DOTFILES_DIR)/scripts/add-tool.sh $(TOOL)
