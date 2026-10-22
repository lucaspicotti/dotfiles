# Clientes do Postgres rodando dentro do container databases-container
for _cmd in psql pg_dump pg_restore; do
  eval "
    $_cmd() {
      if [[ -t 0 ]]; then
        docker exec -it databases-container $_cmd \"\$@\"
      else
        docker exec -i databases-container $_cmd \"\$@\"
      fi
    }
  "
done
unset _cmd

# bat no terminal, cat de verdade em pipes e redirecionamentos (ou sem bat)
cat() {
  if [[ -t 1 ]] && (( $+commands[bat] )); then
    bat --paging=never "$@"
  else
    command cat "$@"
  fi
}

f() {
  fd "$@" | fzf
}
