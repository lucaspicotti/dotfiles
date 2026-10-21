## 📦 Como Instalar

Para instalar todas as dependências e criar os links simbólicos necessários no seu sistema (Ubuntu/Debian), execute o script de instalação automática:

```bash
# 1. Clone o repositório se ainda não o fez
git clone https://github.com/lucaspicotti/dotfiles.git ~/dotfiles

# 2. Acesse a pasta
cd ~/dotfiles

# 3. Dê permissão de execução ao script (se necessário)
chmod +x install.sh

# 4. Rode o script de instalação
./install.sh
```

Sem sudo (pula o apt): `./install`, que é o mesmo que `./install.sh --no-packages`.

### O que o script `install.sh` faz?
- Atualiza as fontes e instala os pacotes do sistema (`zsh`, `tmux`, `git`, `curl`, `build-essential`).
- Instala o **mise** em `~/.local/bin` e, com ele, as ferramentas de CLI listadas em `mise/config.toml` (Neovim, fzf, bat, fd, ripgrep, jq, lazygit, gh, workmux).
- Instala o **kitty** pelo instalador oficial em `~/.local/kitty.app` (com atalho no menu de aplicativos) e o **TPM** com os plugins do tmux.
- Instala o **oh-my-zsh**, o **fnm** e clona os plugins externos do zsh (`zsh-autosuggestions`, `zsh-syntax-highlighting`) em `zsh/custom/plugins/`, que ficam fora do git.
- Configura o **workmux**: linka `workmux/config.yaml`, roda `workmux setup` (hooks de status e skills; precisa de terminal interativo) e linka as skills no Codex, que o setup não cobre.
- Linka as skills de `ai-context/skills` no Claude Code (`~/.claude/skills`, a pasta inteira) e no Codex (`~/.codex/skills`, uma a uma, preservando as skills próprias do Codex).
- Faz backup de qualquer configuração existente em `~/.config` na pasta `~/.dotfiles_backup/` para evitar perdas de dados.
- Cria os links simbólicos necessários de `~/dotfiles` para `~/.config`, além de `~/.zshrc`, `~/.zshenv` e `~/.gitconfig` (ajustes por máquina em `~/.gitconfig.local`, fora do git).
- Linka os scripts de `scripts/` em `~/.local/bin`.
- Roda o bootstrap do **LazyVim** em segundo plano para baixar e sincronizar todos os plugins do Neovim.

## 🐚 zsh

A config do zsh fica em `zsh/`:

- `.zshenv`: PATH e variáveis de ambiente (vale também para shells não interativos).
- `.zshrc`: carrega o oh-my-zsh, o tema e os plugins.
- `custom/`: é o `ZSH_CUSTOM` do oh-my-zsh; todo `*.zsh` aqui é carregado automaticamente (aliases, funções, cores, fnm). O tema `lambda-dracula` fica em `custom/themes/`.

O Node é gerenciado pelo `fnm`, que troca de versão ao entrar numa pasta com `.nvmrc` ou `.node-version`. Versões novas: `fnm install <versão>` e `fnm default <versão>`.

## 🐱 kitty + tmux

O kitty abre direto na sessão tmux `main`, com zsh. Abas e splits ficam por conta do tmux; do kitty só sobram copiar/colar (`Ctrl+Shift+c/v`), fonte (`Ctrl+Shift+=/-/Backspace`), nova janela (`Ctrl+Shift+n`) e recarregar a config (`Ctrl+Shift+F5`).

Os atalhos funcionam sem prefix (o kitty repassa os `Ctrl+Shift+…` ao tmux como CSI u):

| Atalho | Ação |
|---|---|
| `Ctrl+Shift+o` / `Ctrl+Shift+e` | split à direita / abaixo |
| `Ctrl+Shift+h/j/k/l` ou setas | navegar entre splits |
| `Alt+Shift+setas` | redimensionar split |
| `Ctrl+Shift+Enter` | zoom no split |
| `Ctrl+Shift+w` | fechar split |
| `Ctrl+Shift+t` | nova aba |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` (ou `Ctrl+PageDown/PageUp`) | próxima / anterior aba |
| `Alt+1…8` / `Alt+9` | ir para a aba N / última aba |

`Shift+Enter` envia `ESC+Enter` (quebra de linha no zsh, Claude Code, opencode e codex). O prefix do tmux continua `Ctrl+Space`; `prefix ?` lista todos os atalhos.

## 🧰 mise

As ferramentas de CLI ficam em `mise/config.toml` (linkado em `~/.config/mise/config.toml`), todas em `latest`:

- `mise install`: instala o que faltar; `mise upgrade`: atualiza; `mise ls`: lista versões.
- No shell interativo, `zsh/custom/mise.zsh` roda `mise activate`; os shims em `~/.local/share/mise/shims` (no `.zshenv`) cobrem shells não interativos, como hooks e o `run-shell` do tmux.
- Ferramenta nova: `mise use -g <ferramenta>` grava direto no `mise/config.toml` do repositório.

## 🌳 workmux

[workmux](https://github.com/raine/workmux) cria um git worktree com uma janela do tmux por agente. Config global em `workmux/config.yaml`; por projeto, `.workmux.yaml` na raiz. Alias `wm`.

| Atalho (prefix) | Ação |
|---|---|
| `C-s` | dashboard dos agentes |
| `C-w` | dashboard na aba de worktrees |
| `C-t` | sidebar |
| `L` | último agente concluído/aguardando |
| `Tab` | alterna entre os dois últimos agentes |

As skills do workmux (`/worktree`, `/coordinator`, `/merge`, `/rebase`, `/open-pr`, `/workmux`) são instaladas pelo `workmux setup` e ficam fora do git.
