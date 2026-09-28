#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

log() {
  printf '[dotfiles] %s\n' "$1"
}

warn() {
  printf '[dotfiles][warn] %s\n' "$1" >&2
}

# 1. Install dependencies on Ubuntu/Debian
install_system_packages() {
  log "Instalando dependências do sistema..."
  
  # Adiciona PPA do Fish
  if ! apt-cache policy | grep -q "ppa.launchpadcontent.net/fish-shell/release-3"; then
    log "Adicionando PPA do Fish Shell..."
    sudo add-apt-repository ppa:fish-shell/release-3 -y
  fi
  
  # Adiciona PPA do Ghostty
  if ! apt-cache policy | grep -q "ppa.launchpadcontent.net/mkasberg/ghostty-ubuntu"; then
    log "Adicionando PPA do Ghostty..."
    sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu -y
  fi
  
  log "Atualizando pacotes..."
  sudo apt-get update
  
  log "Instalando fish, zsh, tmux, ghostty, git, curl e fzf..."
  sudo apt-get install -y fish zsh tmux ghostty git curl fzf build-essential
}

# 2. Install Neovim (Latest Stable)
install_neovim() {
  if command -v nvim >/dev/null 2>&1; then
    local current_ver
    current_ver=$(nvim --version | head -n1 | cut -d' ' -f2)
    log "Neovim já está instalado: $current_ver"
    return
  fi
  
  log "Neovim não encontrado. Instalando a versão estável mais recente..."
  mkdir -p "$BIN_DIR"
  
  local tmp_dir
  tmp_dir=$(mktemp -d)
  curl -Lo "$tmp_dir/nvim.tar.gz" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"
  
  cp -r "$tmp_dir"/nvim-linux-x86_64/bin/* "$BIN_DIR"/
  mkdir -p "$HOME/.local/lib"
  cp -r "$tmp_dir"/nvim-linux-x86_64/lib/* "$HOME/.local/lib/" || true
  mkdir -p "$HOME/.local/share"
  cp -r "$tmp_dir"/nvim-linux-x86_64/share/* "$HOME/.local/share/"
  
  rm -rf "$tmp_dir"
  log "Neovim instalado com sucesso em $BIN_DIR/nvim"
}

# 3. Helper to backup and create symbolic links
backup_if_exists() {
  local target="$1"

  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/"
    log "Backup criado para: $target"
  fi
}

link_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    log "Já está correto: $target"
    return
  fi

  backup_if_exists "$target"
  ln -s "$source" "$target"
  log "Linkado: $target -> $source"
}

clone_if_missing() {
  local repo="$1"
  local target="$2"

  if [ -d "$target/.git" ]; then
    log "já clonado: $target"
    return
  fi

  git clone --depth=1 "$repo" "$target"
  log "clonado: $repo -> $target"
}

setup_zsh() {
  if ! command -v zsh >/dev/null 2>&1; then
    warn "zsh não encontrado; pulando configuração do zsh"
    return
  fi

  # Linka antes do omz: com KEEP_ZSHRC=yes ele preserva o nosso .zshrc
  link_path "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
  link_path "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "instalando oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  if [ ! -x "$HOME/.local/share/fnm/fnm" ]; then
    log "instalando fnm"
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell
  fi

  local plugins_dir="$DOTFILES/zsh/custom/plugins"
  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
}

setup_kitty() {
  local app="$HOME/.local/kitty.app"

  if [ ! -x "$app/bin/kitty" ]; then
    log "instalando kitty (instalador oficial)"
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
  fi

  ln -sf "$app/bin/kitty" "$app/bin/kitten" "$BIN_DIR/"

  # Atalho no menu de aplicativos, apontando para o binário e ícone do kitty.app
  local apps_dir="$HOME/.local/share/applications"
  mkdir -p "$apps_dir"
  cp "$app/share/applications/kitty.desktop" "$app/share/applications/kitty-open.desktop" "$apps_dir/"
  sed -i "s|Icon=kitty|Icon=$app/share/icons/hicolor/256x256/apps/kitty.png|g; s|Exec=kitty|Exec=$app/bin/kitty|g" \
    "$apps_dir/kitty.desktop" "$apps_dir/kitty-open.desktop"

  link_path "$DOTFILES/kitty" "$CONFIG_DIR/kitty"
}

setup_tmux() {
  link_path "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

  if ! command -v tmux >/dev/null 2>&1; then
    warn "tmux não encontrado; pulando plugins do tmux"
    return
  fi

  clone_if_missing https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
}

main() {
  log "Iniciando a instalação dos dotfiles e dependências..."

  # Detecta sistema operacional e instala pacotes
  if [ -f /etc/debian_version ]; then
    install_system_packages
  else
    warn "Sistema operacional não é baseado em Debian/Ubuntu. Pulando instalação de pacotes via apt."
  fi

  # Instala o Neovim se necessário
  install_neovim

  # Cria os diretórios necessários
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$BIN_DIR"

  # Linkar as configurações
  log "Configurando links simbólicos..."
  
  # fish
  if [ -d "$DOTFILES/fish" ]; then
    link_path "$DOTFILES/fish" "$CONFIG_DIR/fish"
  fi

  # zsh + oh-my-zsh
  setup_zsh

  # ghostty
  if [ -d "$DOTFILES/ghostty" ]; then
    link_path "$DOTFILES/ghostty" "$CONFIG_DIR/ghostty"
  fi

  # Ghostty only discovers themes inside its themes directory.
  if [ -f "$DOTFILES/ghostty/themes/catppuccin-latte.conf" ]; then
    mkdir -p "$CONFIG_DIR/ghostty/themes"
    link_path "$DOTFILES/ghostty/themes/catppuccin-latte.conf" "$CONFIG_DIR/ghostty/themes/Catppuccin Latte"
  fi

  # nvim (LazyVim)
  if [ -d "$DOTFILES/nvim" ]; then
    link_path "$DOTFILES/nvim" "$CONFIG_DIR/nvim"
  fi

  # kitty
  if [ -d "$DOTFILES/kitty" ]; then
    setup_kitty
  fi

  # tmux + TPM
  if [ -f "$DOTFILES/tmux/tmux.conf" ]; then
    setup_tmux
  fi

  # scripts (t, portcheck, bitrix_sync, ...)
  for script in "$DOTFILES"/scripts/*; do
    [ -f "$script" ] || continue
    chmod +x "$script"
    link_path "$script" "$BIN_DIR/$(basename "$script")"
  done

  # bat
  if [ -d "$DOTFILES/bat" ]; then
    link_path "$DOTFILES/bat" "$CONFIG_DIR/bat"
  fi

  # lazygit
  if [ -d "$DOTFILES/lazygit" ]; then
    link_path "$DOTFILES/lazygit" "$CONFIG_DIR/lazygit"
  fi

  # codex: o config.toml fica local (o Codex reescreve o arquivo); só os temas extras são linkados.
  # Tema atual: tui.theme = "dracula", embutido no Codex.
  if [ -d "$DOTFILES/codex/themes" ]; then
    mkdir -p "$HOME/.codex/themes"
    for theme in "$DOTFILES"/codex/themes/*.tmTheme; do
      link_path "$theme" "$HOME/.codex/themes/$(basename "$theme")"
    done
  fi

  # Claude Code: o settings.json fica local (o Claude reescreve o arquivo); só o tema é linkado.
  # Para ativar: /theme -> Dracula (grava "theme": "custom:dracula").
  if [ -d "$DOTFILES/claude/themes" ]; then
    mkdir -p "$HOME/.claude/themes"
    for theme in "$DOTFILES"/claude/themes/*.json; do
      link_path "$theme" "$HOME/.claude/themes/$(basename "$theme")"
    done
  fi

  # opencode
  if [ -f "$DOTFILES/opencode/opencode.jsonc" ]; then
    link_path "$DOTFILES/opencode/opencode.jsonc" "$CONFIG_DIR/opencode/opencode.jsonc"
    link_path "$DOTFILES/opencode/tui.json" "$CONFIG_DIR/opencode/tui.json"
    mkdir -p "$CONFIG_DIR/opencode/themes"
    link_path "$DOTFILES/opencode/catppuccin-latte-blue.json" "$CONFIG_DIR/opencode/themes/catppuccin-latte-blue.json"
  fi

  # 4. Bootstrap/Instalação de plugins do LazyVim (Neovim)
  log "Instalando/Sincronizando plugins do LazyVim..."
  if command -v nvim >/dev/null 2>&1; then
    nvim --headless "+Lazy! sync" +qa || true
  fi

  log "Instalação concluída com sucesso!"
  if [ -d "$BACKUP_DIR" ]; then
    log "Backups das configurações antigas salvos em: $BACKUP_DIR"
  fi
}

main "$@"
