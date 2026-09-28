export ZSH="$HOME/.oh-my-zsh"

# Tudo que é customizado (aliases, funções, temas, plugins) vive no repositório.
# O omz carrega automaticamente todo *.zsh em $ZSH_CUSTOM.
ZSH_CUSTOM="$DOTFILES/zsh/custom"

# Alternativas: robbyrussell
ZSH_THEME="robbyrussell"

# zsh-syntax-highlighting precisa ser o último
plugins=(
  git
  fzf
  fnm
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
