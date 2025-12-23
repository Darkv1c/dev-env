#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Instalar Neovim
curl -L -o /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x /tmp/nvim.appimage
sudo mv /tmp/nvim.appimage /usr/local/bin/nvim

# IMPORTANTE: Crear directorio .config si no existe
mkdir -p ~/.config

# DevPod clona los dotfiles en ~/dotfiles, hacer symlink
ln -sf ~/dotfiles ~/.config/nvim

echo "✅ Neovim instalado correctamente"
