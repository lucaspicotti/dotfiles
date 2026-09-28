# Node via fnm; troca de versão automaticamente ao entrar em pasta com .nvmrc/.node-version
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi
