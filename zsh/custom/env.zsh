# Variáveis usadas só na sessão interativa

export BAT_THEME="Duskfox"

export FZF_DEFAULT_OPTS=" \
    --height=100% \
    --layout=reverse \
    --border \
    --info=inline \
    --prompt='❯ ' \
    --pointer='▶' \
    --marker='✓' \
    --color=bg:#232136,bg+:#433c59,spinner:#f6c177,hl:#eb6f92 \
    --color=fg:#e0def4,header:#65b1cd,info:#9ccfd8,pointer:#eb98c3 \
    --color=marker:#a3be8c,fg+:#eae8ff,prompt:#c4a7e7,hl+:#f083a2 \
    --color=border:#4b4673,label:#65b1cd \
    --preview='if [ -d {} ]; then if command -v eza >/dev/null 2>&1; then eza --tree --level=2 {}; else ls -F {}; fi; elif [ -f {} ]; then if command -v bat >/dev/null 2>&1; then bat --color=always --line-range :200 {}; elif command -v batcat >/dev/null 2>&1; then batcat --color=always --line-range :200 {}; else cat {}; fi; fi'"
