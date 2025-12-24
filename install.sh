#!/bin/bash
set -e

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Install nvim from AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod +x nvim.appimage

# Extract AppImage
./nvim.appimage --appimage-extract

# Copy extracted files
cp squashfs-root/usr/bin/nvim /usr/local/bin/nvim
mkdir -p /usr/local/share
cp -r squashfs-root/usr/share/nvim /usr/local/share/

# Clean up
rm -rf squashfs-root nvim.appimage

# User config (sin sudo)
mkdir -p ~/.config/nvim
cp ./nvim.lua ~/.config/nvim/init.lua

# Set up oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s
echo 'eval "$(oh-my-posh init bash --config /root/.cache/oh-my-posh/themes/jblab_2021.omp.json)"' >> ~/.bashrc
