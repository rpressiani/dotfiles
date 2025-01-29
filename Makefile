DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

COLOR_GREEN=\033[0;32m
COLOR_RED=\033[0;31m
COLOR_BLUE=\033[0;34m
END_COLOR=\033[0m

default: help

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

macos: core-macos packages-macos  # Init MacOS

raspi: raspi-check-prereq core-raspi packages-raspi shell-raspi ssh-port # Init raspi

raspi-check-prereq:
	test -n "$(RASPI_SSH_PORT)" || (echo "$(COLOR_RED)RASPI_SSH_PORT not set$(END_COLOR)" ; exit 1)

core-macos: shell-macos brew # Install MacOS core

core-raspi: # Install raspi core
	sudo apt update
	sudo apt upgrade -y
	sudo apt dist-upgrade -f -y

shell-macos: oh-my-zsh starship-config # Init macOS shell
	mkdir -p ~/.config/zsh
	ln -sfv $(DOTFILES_DIR)/.zshrc ~/.zshrc
	ln -sfv $(DOTFILES_DIR)/config/zsh/aliases.zsh ~/.config/zsh/aliases.zsh

shell-raspi: oh-my-zsh starship-install starship-config # Init raspi shell
	sudo chsh -s /usr/bin/zsh pi
	ln -sfv $(DOTFILES_DIR)/raspberry/.zshrc ~/.zshrc

oh-my-zsh: # Install oh-my-zsh
	if [ ! -d ~/.oh-my-zsh ]; then \
  		curl -fsSLO https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
		sh install.sh --unattended --keep-zshrc && \
		rm install.sh; \
	fi

starship-install: # Install starship
	curl -fsSLO https://starship.rs/install.sh && sudo sh install.sh -y && rm install.sh

starship-config: # Create starship links
	mkdir -p ~/.config
	ln -sfv $(DOTFILES_DIR)/config/starship.toml ~/.config/starship.toml

packages-macos: brew-packages cask-apps # Install packages

packages-raspi: docker
	sudo apt install $(shell cat $(DOTFILES_DIR)/raspberry/pkglist) -y

brew: # Install brew executable
	command -v brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

brew-packages: brew # Install brews
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

cask-apps: brew # Install casks
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

brew-bundle: # Dump brews and casks
	brew bundle dump -f --brews --taps --file $(DOTFILES_DIR)/install/Brewfile
	brew bundle dump -f --cask --file $(DOTFILES_DIR)/install/Caskfile

ssh-port: packages-raspi # Change rapsi SSH port
	test -n "$(RASPI_SSH_PORT)" || (echo "$(COLOR_RED)RASPI_SSH_PORT not set$(END_COLOR)" ; exit 1)
	sudo sed -i 's/#Port 22/Port ${RASPI_SSH_PORT}/g' /etc/ssh/sshd_config
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw allow ${RASPI_SSH_PORT}/tcp
	sudo ufw allow 6443/tcp
	sudo service ufw restart
	sudo service ssh restart

docker:
	command -v docker || (curl -sSL https://get.docker.com | sh && sudo usermod -aG docker ${USER})
