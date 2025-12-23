#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Instalar Neovim con mejor manejo de errores
echo "Descargando Neovim..."
curl -L -o /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage

# Verificar que se descargó un ejecutable, no HTML
if file /tmp/nvim.appimage | grep -q "executable"; then
    echo "✅ AppImage descargado correctamente"
    chmod u+x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
else
    echo "❌ Error: No se descargó el AppImage correctamente"
    echo "Intentando método alternativo..."
    # Alternativa: usar una versión específica
    curl -L -o /tmp/nvim.appimage https://github.com/neovim/neovim/releases/download/v0.10.2/nvim.appimage
    chmod u+x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
fi

# Crear directorio .config
mkdir -p ~/.config

# Hacer symlink a la config de nvim
ln -sf ~/dotfiles ~/.config/nvim

echo "✅ Neovim instalado correctamente"
nvim --version
