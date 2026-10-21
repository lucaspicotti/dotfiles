# workmux: worktrees + janelas do tmux por agente
if (( $+commands[workmux] )); then
  alias wm='workmux'
  source <(workmux completions zsh)
fi
