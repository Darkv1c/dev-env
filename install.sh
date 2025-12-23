#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# apt upgrade
sudo apt-get update
sudo apt-get upgrade

# Instalar Neovim desde tarball precompilado (versión 0.10.x)
echo "Instalando Neovim 0.10.x..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
rm nvim-linux64.tar.gz

# Crear directorio .config
mkdir -p ~/.config

# Hacer symlink a la config de nvim
ln -sf ~/dotfiles ~/.config/nvim

echo "✅ Neovim instalado correctamente"
nvim --version
