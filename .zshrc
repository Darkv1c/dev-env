# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Aliases
alias ls="eza --group-directories-first"

bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Agregar ~/.local/bin al PATH
export PATH="$HOME/.local/bin:$PATH"

# Ensure UTF-8 locale for proper icon/symbol rendering
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Inicializar Starship
eval "$(starship init zsh)"

# Inicializar Zoxide
eval "$(zoxide init zsh)"

export LS_COLORS="$(vivid generate one-dark)"
export EDITOR=nvim
export VISUAL=nvim
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
source ~/.config/zsh/zsh-vi-mode/zsh-vi-mode.zsh
