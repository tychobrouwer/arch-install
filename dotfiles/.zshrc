# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e

unsetopt beep

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Oh My Zsh configuration
export ZSH="$HOME/Projects/oh-my-zsh"
ZSH_THEME="candy"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# User configuration
bindkey '^[[1;5D' emacs-backward-word
bindkey '^[[1;5C' emacs-forward-word
bindkey '^[[3~'   delete-char
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line

# Aliases
alias la='ls -lah'
alias pacman='sudo pacman'
alias pacman-autoremove='sudo pacman -Rns $(pacman -Qtdq)'
alias rm='trash-put' # Put in trash when using rm command
alias clear='clear && echo && neofetch --config $HOME/.config/neofetch/config-short.conf --ascii_distro arch_small'

# Set default libvirt URI to the system one
export LIBVIRT_DEFAULT_URI='qemu:///system'

# Set default editor (for example for virsh net-edit)
export EDITOR=nano

# Show neofetch on shell startup
echo ""
neofetch --config $HOME/.config/neofetch/config-short.conf --ascii_distro arch_small

# Add flutter to path

if [ -d "$HOME/DevTools/flutter/bin" ] ; then
  PATH="$PATH:$HOME/DevTools/flutter/bin"
  CHROME_EXECUTABLE=/usr/bin/google-chrome
fi
