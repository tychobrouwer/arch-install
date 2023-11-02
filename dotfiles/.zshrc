# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Oh My Zsh configuration
export ZSH="$HOME/Repositories/oh-my-zsh"
ZSH_THEME="candy"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# User configuration
bindkey '^[[1;5D' emacs-backward-word
bindkey '^[[1;5C' emacs-forward-word
bindkey '^[[3~'   delete-char
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line

alias la='ls -lah'
alias pacman='sudo pacman'
alias pacman-autoremove='sudo pacman -Rns $(pacman -Qtdq)'
