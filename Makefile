DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

default: help

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

macos: core-macos packages  # Init MacOS

raspi: shell-raspi

core-macos: shell-macos brew # Install MacOS core

oh-my-zsh: # Install oh-my-zsh
	if [ ! -d ~/.oh-my-zsh ]; then \
  		curl -fsSLO https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
		sh install.sh --unattended --keep-zshrc && \
		rm install.sh; \
	fi

starship-config: # Create starship links
	mkdir -p ~/.config
	ln -sfv $(DOTFILES_DIR)/config/starship.toml ~/.config/starship.toml
	
shell-macos: oh-my-zsh starship-config # Create zsh links
	mkdir -p ~/.config/zsh
	ln -sfv $(DOTFILES_DIR)/.zshrc ~/.zshrc
	ln -sfv $(DOTFILES_DIR)/config/zsh/aliases.zsh ~/.config/zsh/aliases.zsh

brew: # Install brew executable
	command -v brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

packages: brew-packages cask-apps # Install packages

brew-packages: brew # Install brews
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

cask-apps: brew # Install casks
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

brew-bundle: # Dump brews and casks
	brew bundle dump -f --brews --taps --file Brewfile
	brew bundle dump -f --brews --cask --file Caskfile

starship-install:
	curl -sS https://starship.rs/install.sh && sudo sh install.sh -y && rm install.sh

shell-raspi: starship-install starship-config
	ln -sfv $(DOTFILES_DIR)/raspberry/.bashrc ~/.bashrc	
