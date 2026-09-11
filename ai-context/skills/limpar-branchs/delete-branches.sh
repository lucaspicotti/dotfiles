#!/usr/bin/env bash

set -u

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Erro: o diretório atual não pertence a um repositório Git."
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "Uso: $0 <branch> [branch...]"
  exit 1
fi

current_branch="$(git branch --show-current)"

protected_branches=(
  "main"
  "master"
  "develop"
)

is_protected() {
  local branch="$1"
  local protected

  for protected in "${protected_branches[@]}"; do
    if [ "$branch" = "$protected" ]; then
      return 0
    fi
  done

  return 1
}

is_used_by_worktree() {
  local branch="$1"

  git worktree list --porcelain |
    grep -Fxq "branch refs/heads/$branch"
}

success=0
failed=0

for branch in "$@"; do
  echo
  echo "Processando: $branch"

  if [ "$branch" = "$current_branch" ]; then
    echo "  Ignorada: é a branch atualmente ativa."
    ((failed += 1))
    continue
  fi

  if is_protected "$branch"; then
    echo "  Ignorada: branch protegida."
    ((failed += 1))
    continue
  fi

  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "  Ignorada: branch local não encontrada."
    ((failed += 1))
    continue
  fi

  if is_used_by_worktree "$branch"; then
    echo "  Ignorada: branch está sendo utilizada por um worktree."
    ((failed += 1))
    continue
  fi

  if git branch -d -- "$branch"; then
    ((success += 1))
  else
    echo "  Não removida."
    echo "  A branch pode possuir commits ainda não mergeados."
    ((failed += 1))
  fi
done

echo
echo "Resultado:"
echo "  Removidas: $success"
echo "  Não removidas: $failed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
