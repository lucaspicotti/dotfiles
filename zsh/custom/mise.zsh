# Ferramentas do mise (ver mise/config.toml); no shell interativo troca os shims pelo PATH real
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
