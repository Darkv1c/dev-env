#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log_info "Starting dotfiles installation from: $SCRIPT_DIR"

# Update
log_step "Updating package lists"
sudo apt-get update

# Install zsh
log_step "Installing zsh"
if command -v zsh &> /dev/null; then
    log_warn "zsh is already installed, skipping"
else
    sudo apt-get install -y zsh
    log_info "zsh installed successfully"
fi

# Install starship prompt
log_step "Installing starship prompt"
if command -v starship &> /dev/null; then
    log_warn "starship is already installed, skipping"
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    log_info "starship installed successfully"
fi

# Set zsh as default shell
log_step "Setting zsh as default shell"
if [ "$SHELL" = "$(which zsh)" ]; then
    log_warn "zsh is already the default shell"
else
    chsh -s $(which zsh) || log_warn "Failed to set zsh as default shell (may require logout)"
fi

# Install nvim from AppImage
log_step "Installing neovim"
if command -v nvim &> /dev/null && [ -d /squashfs-root ]; then
    log_warn "nvim is already installed, skipping"
else
    log_info "Downloading neovim AppImage"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage
    
    log_info "Extracting AppImage"
    ./nvim-linux-x86_64.appimage --appimage-extract
    
    log_info "Installing nvim globally"
    # Remove existing installation if it exists
    if [ -d /squashfs-root ]; then
        log_info "Removing old nvim installation"
        sudo rm -rf /squashfs-root
    fi
    sudo mv squashfs-root /
    sudo ln -sf /squashfs-root/AppRun /usr/bin/nvim
    
    log_info "Cleaning up"
    rm -f nvim-linux-x86_64.appimage
    
    log_info "nvim installed successfully"
fi

# Neovim configuration
log_step "Setting up neovim configuration"
mkdir -p ~/.config/nvim/lua/plugins

if [ -f "$SCRIPT_DIR/.config/nvim/init.lua" ]; then
    cp "$SCRIPT_DIR/.config/nvim/init.lua" ~/.config/nvim/init.lua
    log_info "Copied init.lua"
else
    log_error "init.lua not found in $SCRIPT_DIR/.config/nvim/"
fi

for plugin_file in core.lua study.lua work.lua; do
    if [ -f "$SCRIPT_DIR/.config/nvim/lua/plugins/$plugin_file" ]; then
        cp "$SCRIPT_DIR/.config/nvim/lua/plugins/$plugin_file" ~/.config/nvim/lua/plugins/$plugin_file
        log_info "Copied $plugin_file"
    else
        log_warn "$plugin_file not found, skipping"
    fi
done

# Zsh and Starship configuration
log_step "Setting up shell configuration"
mkdir -p ~/.config

if [ -f "$SCRIPT_DIR/.zshrc" ]; then
    cp "$SCRIPT_DIR/.zshrc" ~/.zshrc
    log_info "Copied .zshrc"
else
    log_error ".zshrc not found"
fi

if [ -f "$SCRIPT_DIR/.config/starship.toml" ]; then
    cp "$SCRIPT_DIR/.config/starship.toml" ~/.config/starship.toml
    log_info "Copied starship.toml"
else
    log_error "starship.toml not found"
fi

# Install yazi (file manager)
log_step "Installing yazi file manager"
if command -v yazi &> /dev/null; then
    log_warn "yazi is already installed, skipping"
else
    log_info "Downloading yazi"
    # Install unzip if not available
    if ! command -v unzip &> /dev/null; then
        sudo apt-get install -y unzip
    fi
    curl -LO https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
    unzip -q yazi-x86_64-unknown-linux-gnu.zip
    sudo mv yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
    rm -rf yazi-x86_64-unknown-linux-gnu yazi-x86_64-unknown-linux-gnu.zip
    log_info "yazi installed successfully"
fi

# Install Open Code
log_step "Installing OpenCode"
if command -v opencode &> /dev/null; then
    log_warn "opencode is already installed, skipping"
else
    curl -fsSL https://opencode.ai/install | bash
    sudo apt-get install -y procps lsof
    log_info "OpenCode installed successfully"
fi

log_step "Setting up OpenCode configuration"
mkdir -p ~/.config/opencode
if [ -f "$SCRIPT_DIR/opencode.json" ]; then
    cp "$SCRIPT_DIR/opencode.json" ~/.config/opencode/opencode.json
    log_info "Copied opencode.json"
else
    log_warn "opencode.json not found, skipping"
fi

log_info ""
log_info "✓ Installation complete!"
log_info "Please log out and log back in for zsh to take effect."
log_info "Or run: exec zsh"
