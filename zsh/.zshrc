export ZSH="$HOME/.oh-my-zsh"

# Tudo que é customizado (aliases, funções, temas, plugins) vive no repositório.
# O omz carrega automaticamente todo *.zsh em $ZSH_CUSTOM.
ZSH_CUSTOM="$DOTFILES/zsh/custom"

# Usa as cores ANSI do terminal (Dracula no kitty). Alternativas: robbyrussell (padrão do omz)
ZSH_THEME="gozilla"

# zsh-syntax-highlighting precisa ser o último
plugins=(
  git
  fzf
  fnm
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
