# Lido por todo zsh (interativo ou não). Mantenha aqui só variáveis de ambiente.

# Raiz do repositório de dotfiles, resolvida a partir do symlink ~/.zshenv
export DOTFILES="${${(%):-%x}:A:h:h}"

# PATH sem duplicatas; os primeiros têm prioridade
typeset -U path
path=(
  $HOME/.local/share/mise/shims
  $HOME/.local/bin
  $HOME/go/bin
  /usr/local/go/bin
  $HOME/.config/composer/vendor/bin
  $HOME/.local/share/fnm
  $path
)

export CPM_SOURCE_CACHE="$HOME/.cache/CPM"
