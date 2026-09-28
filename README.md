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

### O que o script `install.sh` faz?
- Adiciona os PPAs oficiais do **Fish Shell** e **Ghostty**.
- Atualiza as fontes e instala os pacotes do sistema (`fish`, `zsh`, `ghostty`, `git`, `curl`, `fzf`, `build-essential`).
- Instala o **oh-my-zsh**, o **fnm** e clona os plugins externos do zsh (`zsh-autosuggestions`, `zsh-syntax-highlighting`) em `zsh/custom/plugins/`, que ficam fora do git.
- Verifica se o **Neovim** está presente; se não estiver, baixa a versão estável mais recente do Neovim (AppImage/Binary) e extrai no caminho local do usuário (`~/.local/bin/nvim`).
- Faz backup de qualquer configuração existente em `~/.config` na pasta `~/.dotfiles_backup/` para evitar perdas de dados.
- Cria os links simbólicos necessários de `~/dotfiles` para `~/.config`, além de `~/.zshrc` e `~/.zshenv`.
- Linka os scripts de `scripts/` em `~/.local/bin`.
- Roda o bootstrap do **LazyVim** em segundo plano para baixar e sincronizar todos os plugins do Neovim.

## 🐚 zsh

A config do zsh fica em `zsh/`:

- `.zshenv`: PATH e variáveis de ambiente (vale também para shells não interativos).
- `.zshrc`: carrega o oh-my-zsh, o tema e os plugins.
- `custom/`: é o `ZSH_CUSTOM` do oh-my-zsh; todo `*.zsh` aqui é carregado automaticamente (aliases, funções, cores, fnm). O tema `lambda-dracula` fica em `custom/themes/`.

O Node é gerenciado pelo `fnm`, que troca de versão ao entrar numa pasta com `.nvmrc` ou `.node-version`. Versões novas: `fnm install <versão>` e `fnm default <versão>`.
