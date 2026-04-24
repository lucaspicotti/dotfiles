return {
  "tpope/vim-fugitive",

  -- Cheat sheet (vim-fugitive)
  -- --------------------------------------------------

  -- Status / geral
  -- :Git / :G        abre status

  -- Dentro do :Git
  -- -    stage / unstage
  -- s    stage
  -- u    unstage
  -- X    descartar mudanças

  -- Commit
  -- cc   commit
  -- ca   commit --amend
  -- ce   editar commit

  -- --------------------------------------------------

  -- Branch / checkout
  -- :Git checkout branch
  -- :Git switch branch
  -- :Git checkout -b nova-branch

  -- --------------------------------------------------

  -- Push / Pull
  -- :Git push
  -- :Git pull
  -- :Git fetch

  -- --------------------------------------------------

  -- Diff
  -- :Git diff
  -- :Gdiffsplit
  -- :Gvdiffsplit

  -- --------------------------------------------------

  -- Log / histórico
  -- :Git log
  -- :Git log --oneline
  -- Enter (no log) abre commit

  -- --------------------------------------------------

  -- Blame
  -- :Git blame

  -- --------------------------------------------------

  -- Arquivos em commits
  -- :Gedit HEAD~1:arquivo.php
  -- :Gedit <hash>:arquivo.php

  -- --------------------------------------------------

  -- Merge / conflitos
  -- :Gdiffsplit
  -- :diffget
  -- :diffput

  -- --------------------------------------------------

  -- Reset / restore
  -- :Git reset
  -- :Git reset --hard
  -- :Git restore arquivo.php

  -- --------------------------------------------------

  -- Stash
  -- :Git stash
  -- :Git stash pop
  -- :Git stash list

  -- --------------------------------------------------

  -- Rebase
  -- :Git rebase -i HEAD~3

  -- --------------------------------------------------

  -- Comandos diretos
  -- :Git add .
  -- :Git commit -m "msg"
  -- :Git push origin main

  -- --------------------------------------------------

  -- Navegação (buffers do fugitive)
  -- q       sair
  -- Enter   abrir
  -- -       stage/unstage
  -- cc      commit
}
