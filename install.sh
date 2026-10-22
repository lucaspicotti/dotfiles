#!/usr/bin/env bash
# Uso: ./install.sh                 instala pacotes do sistema (apt), ferramentas (mise) e links
#      ./install.sh --no-packages   pula o apt (sem sudo); o resto roda igual
#      ./install.sh --chsh          também troca o shell de login para zsh
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

# Como root (ex.: container) não há sudo
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

# 1. Pacotes do sistema (Ubuntu/Debian). Ferramentas de CLI ficam com o mise.
install_system_packages() {
  log "Instalando dependências do sistema..."

  log "Atualizando pacotes..."
  $SUDO apt-get update

  # unzip: instalador do fnm; xz-utils/fontconfig: Nerd Font; build-essential: parsers do treesitter
  log "Instalando pacotes obrigatórios..."
  $SUDO apt-get install -y zsh tmux git curl ca-certificates build-essential tree unzip xz-utils fontconfig file

  # Usados pelo preview do fzf e pelo clipboard; nem toda versão do Ubuntu/Debian tem todos (eza)
  local pkg
  for pkg in xsel eza chafa poppler-utils; do
    $SUDO apt-get install -y "$pkg" || warn "pacote opcional não instalado: $pkg"
  done
}

# 2. Helper to backup and create symbolic links
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

# 3. Ferramentas de CLI (nvim, fzf, bat, fd, rg, jq, lazygit, gh, tree-sitter, workmux) via mise/config.toml
setup_mise() {
  if ! command -v mise >/dev/null 2>&1 && [ ! -x "$BIN_DIR/mise" ]; then
    log "instalando mise"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$BIN_DIR/mise" MISE_INSTALL_HELP=0 sh
  fi

  link_path "$DOTFILES/mise/config.toml" "$CONFIG_DIR/mise/config.toml"

  local mise
  mise="$(command -v mise || echo "$BIN_DIR/mise")"
  log "instalando ferramentas do mise"
  # Uma falha de rede não deve derrubar o resto da instalação
  "$mise" install || warn "algumas ferramentas do mise falharam; rode de novo: mise install"

  # Deixa as ferramentas visíveis para o resto do script (nvim, workmux)
  export PATH="$HOME/.local/share/mise/shims:$PATH"
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

# Node LTS como default do fnm, só se ainda não houver um default
setup_node() {
  local fnm="$HOME/.local/share/fnm/fnm"
  [ -x "$fnm" ] || return 0

  if [ -e "$HOME/.local/share/fnm/aliases/default" ]; then
    log "Node default já definido: $("$fnm" default)"
    return
  fi

  local version
  version="$("$fnm" ls-remote --lts --latest | awk '{print $1}')"
  if [ -z "$version" ]; then
    warn "não foi possível descobrir a última versão LTS do Node; rode: fnm install --lts"
    return
  fi

  log "instalando Node $version (LTS)"
  "$fnm" install "$version"
  "$fnm" default "$version"
}

# Só com --chsh: login (SSH, TTY) passa a abrir zsh; o kitty já abre zsh de qualquer jeito
change_login_shell() {
  local zsh_path current
  zsh_path="$(command -v zsh || true)"
  if [ -z "$zsh_path" ]; then
    warn "zsh não encontrado; shell de login mantido"
    return
  fi

  current="$(getent passwd "$USER" | cut -d: -f7)"
  if [ "$current" = "$zsh_path" ]; then
    log "shell de login já é $zsh_path"
    return
  fi

  if ! grep -qx "$zsh_path" /etc/shells; then
    echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
  fi

  # Usuários de rede (LDAP/SSSD) não podem usar chsh
  if chsh -s "$zsh_path"; then
    log "shell de login trocado para $zsh_path (vale no próximo login)"
  else
    warn "chsh falhou; se o usuário for de rede (LDAP), peça a troca ao administrador"
  fi
}

# JetBrainsMono Nerd Font, usada no kitty (ícones no nvim, tmux e workmux)
install_nerd_font() {
  if ! command -v fc-list >/dev/null 2>&1; then
    warn "fontconfig não encontrado; pulando a Nerd Font"
    return
  fi

  if fc-list | grep -q "JetBrainsMono NFM"; then
    log "JetBrainsMono Nerd Font já instalada"
    return
  fi

  local fonts_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  log "instalando JetBrainsMono Nerd Font"
  mkdir -p "$fonts_dir"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar -xJ -C "$fonts_dir"
  fc-cache -f "$fonts_dir" >/dev/null
}

setup_kitty() {
  local app="$HOME/.local/kitty.app"

  install_nerd_font

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

setup_workmux() {
  # Só o arquivo: o workmux grava estado em ~/.config/workmux
  link_path "$DOTFILES/workmux/config.yaml" "$CONFIG_DIR/workmux/config.yaml"

  if ! command -v workmux >/dev/null 2>&1; then
    warn "workmux não encontrado; pulando hooks e skills"
    return
  fi

  # Hooks de status e skills (Claude Code, Codex, OpenCode...); o setup exige terminal interativo
  if [ -t 0 ] && [ -t 1 ]; then
    workmux setup || warn "workmux setup falhou; rode manualmente: workmux setup"
  else
    warn "sem terminal interativo; rode depois: workmux setup"
  fi

  # Os hooks rodam em /bin/sh, sem o PATH do mise: usa o caminho absoluto do shim
  local claude_settings="$HOME/.claude/settings.json"
  if [ -f "$claude_settings" ]; then
    sed -i 's|"command": "workmux |"command": "$HOME/.local/share/mise/shims/workmux |' "$claude_settings"
  fi

  # Mesmo problema nos hooks do Codex; o caminho vai expandido (o Codex pede para confiar de novo)
  local codex_hooks="$HOME/.codex/hooks.json"
  if [ -f "$codex_hooks" ]; then
    sed -i "s|\"command\": \"workmux |\"command\": \"$HOME/.local/share/mise/shims/workmux |" "$codex_hooks"
  fi

}

# Skills de ai-context/skills no Codex, uma a uma, porque ele mantém skills próprias
# em ~/.codex/skills (o Claude Code recebe a pasta inteira, ver main)
setup_codex_skills() {
  [ -d "$HOME/.codex" ] || return 0

  local skill name target
  for skill in "$DOTFILES"/ai-context/skills/*/; do
    skill="${skill%/}"
    name="$(basename "$skill")"
    # synced/ é sincronizado de fora e não é uma skill
    [ "$name" = "synced" ] && continue
    target="$HOME/.codex/skills/$name"
    # Não sobrescreve skills que o próprio Codex instalou (ex.: graphify)
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      log "skill própria do Codex mantida: $target"
      continue
    fi
    link_path "$skill" "$target"
  done
}

main() {
  local install_packages=1
  local change_shell=0
  local arg
  for arg in "$@"; do
    case "$arg" in
      --no-packages) install_packages=0 ;;
      --chsh) change_shell=1 ;;
      -h|--help)
        sed -n '2,4p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        return
        ;;
      *)
        warn "opção desconhecida: $arg"
        return 1
        ;;
    esac
  done

  log "Iniciando a instalação dos dotfiles e dependências..."

  # Detecta sistema operacional e instala pacotes
  if [ "$install_packages" = 0 ]; then
    log "Pulando pacotes do sistema (--no-packages)."
  elif [ -f /etc/debian_version ]; then
    install_system_packages
  else
    warn "Sistema operacional não é baseado em Debian/Ubuntu. Pulando instalação de pacotes via apt."
  fi

  # Cria os diretórios necessários
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$BIN_DIR"

  # Ferramentas de CLI (inclui Neovim e workmux)
  setup_mise

  # Linkar as configurações
  log "Configurando links simbólicos..."

  # zsh + oh-my-zsh + fnm
  setup_zsh
  setup_node
  if [ "$change_shell" = 1 ]; then
    change_login_shell
  fi

  # git (o ignore global é lido de ~/.config/git/ignore)
  link_path "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
  link_path "$DOTFILES/git/ignore" "$CONFIG_DIR/git/ignore"

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

  # fd
  if [ -d "$DOTFILES/fd" ]; then
    link_path "$DOTFILES/fd/config" "$CONFIG_DIR/fd/config"
    link_path "$DOTFILES/fd/fdignore" "$CONFIG_DIR/fd/ignore"
  fi

  # lazygit
  if [ -d "$DOTFILES/lazygit" ]; then
    link_path "$DOTFILES/lazygit" "$CONFIG_DIR/lazygit"
  fi

  # codex: o config.toml fica local (o Codex reescreve o arquivo).
  # Tema: tui.theme = "dracula", embutido no Codex.

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
  fi

  # Skills do Claude Code; antes do workmux, que grava as dele em ~/.claude/skills
  link_path "$DOTFILES/ai-context/skills" "$HOME/.claude/skills"

  # workmux: config, hooks de status e skills (depois do Claude/Codex/opencode)
  if [ -f "$DOTFILES/workmux/config.yaml" ]; then
    setup_workmux
  fi

  # Skills no Codex, incluindo as que o workmux acabou de instalar
  setup_codex_skills

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
