# Configurações de Mapeamento de Teclas (Keymaps) do Neovim

Este arquivo documenta todos os atalhos personalizados configurados no Neovim.

## 1. Atalhos Gerais (Gerais & Navegação)
*Configurados em [keymaps.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/config/keymaps.lua)*

| Atalho | Modo | Ação / Comando | Descrição |
|---|---|---|---|
| `<Esc>` | Normal | `:nohlsearch` | Limpa o destaque de busca (highlight) após pesquisar uma palavra. |
| `<leader>Q` | Normal | `:bufdo bdelete` | Fecha todos os buffers (arquivos abertos) de uma vez. |
| `[d` | Normal | `vim.diagnostic.get_prev` | Pula para o erro/alerta anterior de diagnóstico. |
| `]d` | Normal | `vim.diagnostic.get_next` | Pula para o próximo erro/alerta de diagnóstico. |
| `gf` | Qualquer | `:edit <cfile>` | Abre/cria o arquivo sob o cursor se ele não existir. |
| `<` | Visual | `<gv` | Identação para a esquerda (mantém a seleção ativa). |
| `>` | Visual | `>gv` | Identação para a direita (mantém a seleção ativa). |
| `y` | Visual | `myy'y` | Copia texto (yank) sem mover o cursor da posição original. |
| `Y` | Visual | `myY'y` | Copia texto da linha (yank) sem mover o cursor da posição original. |
| `k` | Normal | `gk` / `k` | Movimenta para cima. Se a linha estiver quebrada (wrap), move visualmente linha por linha. |
| `j` | Normal | `gj` / `j` | Movimenta para baixo. Se a linha estiver quebrada (wrap), move visualmente linha por linha. |
| `p` | Visual | `"_dP` | Cola texto sem sobrescrever a área de transferência (clipboard) com o texto substituído. |
| `;;` | Inserção | `<Esc>A;<Esc>` | Adiciona ponto e vírgula `;` no final da linha e volta para o modo Normal. |
| `,,` | Inserção | `<Esc>A,<Esc>` | Adiciona vírgula `,` no final da linha e volta para o modo Normal. |
| `q:` | Normal | `:q` | Desabilita o histórico de comandos acidental e apenas fecha a janela (`:q`). |
| `<C-Up>` | Normal | `:resize +2` | Aumenta o tamanho da janela atual verticalmente. |
| `<C-Down>` | Normal | `:resize -2` | Diminui o tamanho da janela atual verticalmente. |
| `<C-Left>` | Normal | `:vertical resize -2` | Diminui o tamanho da janela atual horizontalmente. |
| `<C-Right>` | Normal | `:vertical resize +2` | Aumenta o tamanho da janela atual horizontalmente. |
| `<A-j>` | Inserção | Move a linha atual para baixo e volta ao modo Inserção. |
| `<A-k>` | Inserção | Move a linha atual para cima e volta ao modo Inserção. |
| `<A-j>` | Normal | Move a linha atual para baixo. |
| `<A-k>` | Normal | Move a linha atual para cima. |
| `<A-j>` | Visual | Move a seleção visual para baixo (com identação automática). |
| `<A-k>` | Visual | Move a seleção visual para cima (com identação automática). |
| `<leader>t` | Normal | `require("snacks").terminal()` | Abre/fecha (Toggle) o terminal flutuante integrado do Snacks. |

## 2. LSP (Language Server Protocol)
*Configurados em [lspconfig.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/plugins/lsp/lspconfig.lua)*

Esses atalhos são ativados automaticamente apenas quando um servidor de linguagem (LSP) está ativo no buffer.

| Atalho | Modo | Comando | Descrição |
|---|---|---|---|
| `<leader>d` | Normal | `vim.diagnostic.open_float` | Exibe os detalhes dos erros/alertas da linha atual em uma janela flutuante. |
| `gd` | Normal | `:Telescope lsp_definitions` | Vai para a definição da classe/função/variável sob o cursor (via Telescope). |
| `ga` | Normal | `vim.lsp.buf.code_action` | Abre as ações corretivas/refatorações disponíveis pelo LSP. |
| `gi` | Normal | `:Telescope lsp_implementations` | Vai para a implementação (via Telescope). |
| `gr` | Normal | `:Telescope lsp_references` | Lista todas as referências/usos do símbolo sob o cursor (via Telescope). |
| `K` | Normal | `vim.lsp.buf.hover` | Exibe a documentação/assinatura da função sob o cursor em pop-up. |
| `<leader>rn` | Normal | `vim.lsp.buf.rename` | Renomeia o símbolo atual em todos os arquivos do projeto de forma inteligente. |
| `<leader>lr` | Normal | `:LspRestart` | Reinicia todos os servidores de linguagem ativos. |

## 3. Autocompletar & Sugestões (nvim-cmp & Copilot)
*Configurados em [cmp.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/plugins/lsp/cmp.lua) e [copilot.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/plugins/lsp/copilot.lua)*

| Atalho | Modo | Ação | Descrição |
|---|---|---|---|
| `<Tab>` | Inserção | Confirmar / Aceitar | Se o menu do CMP estiver aberto, confirma a seleção do autocomplete. Caso contrário, se uma sugestão do Copilot estiver visível, aceita a sugestão. |
| `<C-j>` | Inserção | Avançar no menu | Seleciona o próximo item da lista de autocompletar do CMP. |
| `<C-k>` | Inserção | Voltar no menu | Seleciona o item anterior na lista de autocompletar do CMP. |
| `<C-e>` | Inserção | Fechar menu | Cancela/fecha o menu de autocompletar do CMP. |
| `<leader>ct` | Normal | Alternar Copilot | Ativa ou desativa o trigger automático das sugestões em linha do Copilot (ghost text). |
| `<M-]>` (Alt+`]`) | Inserção | Próxima sugestão | Exibe a próxima sugestão do Copilot (ou força a exibição manual se estiver desligado). |
| `<M-[>` (Alt+`[`) | Inserção | Sugestão anterior | Exibe a sugestão anterior do Copilot. |
| `<C-]>` (Ctrl+`]`) | Inserção | Descartar dica | Oculta/cancela a sugestão atual do Copilot exibida na tela. |

## 4. Integração Git (gitsigns)
*Configurados em [gitsigns.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/plugins/git/gitsigns.lua)*

| Atalho | Modo | Comando | Descrição |
|---|---|---|---|
| `]h` | Normal | `:Gitsigns next_hunk` | Vai para a próxima alteração (hunk) de Git no arquivo. |
| `[h` | Normal | `:Gitsigns prev_hunk` | Vai para a alteração anterior (hunk) de Git no arquivo. |
| `gs` | Normal | `:Gitsigns stage_hunk` | Adiciona a alteração (hunk) atual ao stage do Git (equivalente a `git add`). |
| `gS` | Normal | `:Gitsigns undo_stage_hunk` | Remove a alteração atual do stage do Git. |
| `gp` | Normal | `:Gitsigns preview_hunk` | Abre um pop-up flutuante exibindo o diff da alteração sob o cursor. |
| `gb` | Normal | `:Gitsigns blame_line` | Mostra quem fez a última alteração na linha atual e em qual commit (Git Blame). |

## 5. Navegador de Arquivos (oil.nvim)
*Configurados em [oil.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/plugins/util/oil.lua)*

| Atalho | Modo | Comando | Descrição |
|---|---|---|---|
| `-` | Normal | `:Oil` | Abre o navegador de arquivos Oil no diretório pai do arquivo atual. |

## 6. Diagnósticos Avançados (trouble.nvim)
*Configurados em [trouble.lua](file:///home/lucaspicotti/dotfiles/nvim/lua/plugins/util/trouble.lua)*

| Atalho | Modo | Comando | Descrição |
|---|---|---|---|
| `<leader>xx` | Normal | `:Trouble diagnostics toggle` | Abre/fecha painel com todos os erros e alertas do projeto. |
| `<leader>xX` | Normal | `:Trouble diagnostics toggle filter.buf=0` | Abre/fecha painel com erros e alertas apenas do arquivo atual. |
| `<leader>cs` | Normal | `:Trouble symbols toggle` | Exibe a árvore estrutural (símbolos) do arquivo atual. |
| `<leader>cl` | Normal | `:Trouble lsp toggle` | Abre painel com definições/referências do LSP para navegação. |
| `<leader>xL` | Normal | `:Trouble loclist toggle` | Abre/fecha o painel do `Location List`. |
| `<leader>xQ` | Normal | `:Trouble qflist toggle` | Abre/fecha o painel do `Quickfix List`. |

## 7. Ferramentas Extras (Floaterm & Phpactor & Commentary)
*Configurados em seus respectivos plugins*

| Atalho | Modo | Comando | Descrição |
|---|---|---|---|
| `<F1>` | Todos | `:FloatermToggle` | Abre/fecha o terminal flutuante (Funciona em modo Normal, Inserção e Terminal). |
| `<leader>pm` | Normal | `:PhpactorContextMenu` | Abre o menu de contexto do Phpactor para refatoração e ações rápidas (apenas em PHP). |
| `<leader>pn` | Normal | `:PhpactorClassNew` | Atalho rápido para gerar uma nova classe PHP em arquivos vazios. |
| `gcap` | Normal | Comentário | Comenta o parágrafo atual mantendo a posição original do cursor. |
