DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

default: help

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

macos: core-macos packages  # Init MacOS

core-macos: shell brew
	
shell: starship # Create zsh links
	mkdir -p ~/.config/zsh
	ln -sfv $(DOTFILES_DIR)/.zshrc ~/.zshrc
	ln -sfv $(DOTFILES_DIR)/config/zsh/aliases.zsh ~/.config/zsh/aliases.zsh

starship: # Create starship links
	mkdir -p ~/.config
	ln -sfv $(DOTFILES_DIR)/config/starship.toml ~/.config/starship.toml

brew-bundle: # Dump brews and casks
	brew bundle dump -f --brews --taps --file Brewfile
	brew bundle dump -f --brews --cask --file Caskfile

brew:
	command -v brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

packages: brew-packages cask-apps

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true
