---
name: clean-local-branches
description: Lista branches Git locais e permite ao usuário selecionar uma ou mais branches para remoção segura.
---

# Clean Local Branches

Use esta skill quando o usuário quiser limpar, remover ou excluir branches locais de um repositório Git.

## Objetivo

Permitir que o usuário visualize as branches locais existentes no repositório atual, selecione uma ou mais delas e remova as selecionadas usando o script `scripts/delete-branches.sh`.

## Regras

- Trabalhe somente com branches locais.
- Nunca exclua branches remotas.
- Nunca exclua a branch atualmente ativa.
- Não selecione branches automaticamente.
- Nunca execute a exclusão antes de o usuário escolher explicitamente as branches.
- Sempre disponibilize uma opção de cancelamento.
- Por padrão, proteja as branches:
  - `main`
  - `master`
  - `develop`
- Não utilize `git branch -D` diretamente.
- A exclusão deve ser feita exclusivamente através de `scripts/delete-branches.sh`.
- Se nenhuma branch puder ser removida, informe o usuário e encerre.
- Se o usuário cancelar, não execute nenhum comando destrutivo.

## Fluxo

### 1. Validar o repositório

Execute:

```sh
git rev-parse --is-inside-work-tree
```

Se não estiver dentro de um repositório Git, informe o usuário e encerre.

### 2. Descobrir a branch atual

Execute:

```sh
git branch --show-current
```

### 3. Listar branches locais

Execute:

```sh
git for-each-ref --format='%(refname:short)' refs/heads/
```

Remova da lista:

- a branch atual;
- `main`;
- `master`;
- `develop`.

Considere também branches associadas a outros worktrees. Para inspecioná-las, execute:

```sh
git worktree list --porcelain
```

Não ofereça para exclusão branches que estejam atualmente checked out em qualquer worktree.

### 4. Solicitar seleção

Apresente todas as branches restantes ao usuário.

O usuário deve poder:

- escolher uma branch;
- escolher várias branches;
- cancelar.

Não presuma quais branches devem ser removidas.

### 5. Executar remoção

Depois da seleção explícita do usuário, execute:

```sh
scripts/delete-branches.sh <branch1> <branch2> ...
```

Passe cada branch como um argumento separado.

Não tente reproduzir a lógica de exclusão diretamente na skill. O script é responsável pelas validações finais antes de remover cada branch.

### 6. Resultado

Mostre:

- branches removidas;
- branches que não puderam ser removidas;
- motivo das falhas.

Se uma branch possuir commits não mergeados, o script deve recusar sua exclusão.

Não force a exclusão automaticamente.

## Segurança

A seleção feita pelo usuário não substitui as validações do script.

Mesmo que uma branch seja passada ao script, ele deve recusar a operação quando:

- for a branch atualmente ativa;
- for uma branch protegida;
- não existir localmente;
- estiver sendo utilizada por outro worktree;
- o Git considerar que ela possui commits não mergeados.

Nunca altere o script para utilizar `git branch -D` sem que o usuário solicite explicitamente uma funcionalidade de exclusão forçada.
