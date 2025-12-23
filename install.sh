#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Instalar Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
sudo mv nvim.appimage /usr/local/bin/nvim

# Enlazar config (el repo ya está clonado en ~/dotfiles por DevPod)
ln -sf ~/dotfiles ~/.config/nvim

echo "Neovim instalado correctamente"
