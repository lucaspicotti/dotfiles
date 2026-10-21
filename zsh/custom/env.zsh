# Variáveis usadas só na sessão interativa

fzf_preview() {
    local target="$1"
    local mime

    if [[ -d "$target" ]]; then
        if command -v eza >/dev/null 2>&1; then
            eza --tree --level=2 --color=always "$target"
        else
            ls -F "$target"
        fi
        return
    fi

    [[ -f "$target" ]] || return
    mime=$(file --mime-type -Lb -- "$target")

    case "$mime" in
        text/*|application/json|application/xml|application/javascript)
            if command -v bat >/dev/null 2>&1; then
                bat --color=always --line-range :200 -- "$target"
            elif command -v batcat >/dev/null 2>&1; then
                batcat --color=always --line-range :200 -- "$target"
            else
                sed -n '1,200p' -- "$target"
            fi
            ;;
        application/pdf)
            if command -v pdftotext >/dev/null 2>&1; then
                if command -v bat >/dev/null 2>&1; then
                    pdftotext -f 1 -l 3 -layout -- "$target" - | bat --color=always --language=markdown
                elif command -v batcat >/dev/null 2>&1; then
                    pdftotext -f 1 -l 3 -layout -- "$target" - | batcat --color=always --language=markdown
                else
                    pdftotext -f 1 -l 3 -layout -- "$target" -
                fi
            else
                printf 'PDF encontrado. Instale poppler-utils para visualizar o texto.\n'
            fi
            ;;
        image/*)
            if command -v chafa >/dev/null 2>&1; then
                chafa --format=symbols --size=80x30 -- "$target"
            else
                printf 'Imagem encontrada. Instale chafa para visualizar imagens.\n'
            fi
            ;;
        *)
            file -- "$target"
            ;;
    esac
}

export FZF_DEFAULT_OPTS=" \
    --height=100% \
    --preview-window='right,70%,border-left' \
    --layout=reverse \
    --border \
    --info=inline \
    --prompt='❯ ' \
    --pointer='▶' \
    --marker='✓' \
    --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 \
    --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 \
    --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 \
    --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4 \
    --color=border:#6272a4,label:#8be9fd \
    --preview='~/.local/bin/fzf_preview {}'"
