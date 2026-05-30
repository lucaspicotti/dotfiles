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
- Atualiza as fontes e instala os pacotes do sistema (`fish`, `ghostty`, `git`, `curl`, `fzf`, `build-essential`).
- Verifica se o **Neovim** está presente; se não estiver, baixa a versão estável mais recente do Neovim (AppImage/Binary) e extrai no caminho local do usuário (`~/.local/bin/nvim`).
- Faz backup de qualquer configuração existente em `~/.config` na pasta `~/.dotfiles_backup/` para evitar perdas de dados.
- Cria os links simbólicos necessários de `~/dotfiles` para `~/.config`.
- Roda o bootstrap do **LazyVim** em segundo plano para baixar e sincronizar todos os plugins do Neovim.
