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
  
  log "Instalando fish, ghostty, git, curl e fzf..."
  sudo apt-get install -y fish ghostty git curl fzf build-essential
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

  # ghostty
  if [ -d "$DOTFILES/ghostty" ]; then
    link_path "$DOTFILES/ghostty" "$CONFIG_DIR/ghostty"
  fi

  # nvim (LazyVim)
  if [ -d "$DOTFILES/nvim" ]; then
    link_path "$DOTFILES/nvim" "$CONFIG_DIR/nvim"
  fi

  # kitty (opcional)
  if [ -d "$DOTFILES/kitty" ]; then
    link_path "$DOTFILES/kitty" "$CONFIG_DIR/kitty"
  fi

  # tmux (opcional)
  if [ -f "$DOTFILES/tmux/tmux.conf" ]; then
    link_path "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
  fi

  # script t (opcional)
  if [ -f "$DOTFILES/scripts/t" ]; then
    link_path "$DOTFILES/scripts/t" "$BIN_DIR/t"
    chmod +x "$BIN_DIR/t"
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
