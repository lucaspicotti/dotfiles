if status is-interactive
    fish_add_path ~/.local/bin
    fish_add_path ~/go/bin

    abbr -a vim nvim

    # Theme configurations (Dracula Alucard)
    set -gx BAT_THEME "Dracula Alucard"
    
    set -gx FZF_DEFAULT_OPTS " \
        --height=100% \
        --layout=reverse \
        --border \
        --info=inline \
        --prompt='❯ ' \
        --pointer='▶' \
        --marker='✓' \
        --color=bg+:#cfcfde,spinner:#a34d14,hl:#cb3a2a \
        --color=fg:#1f1f1f,header:#cb3a2a,info:#644ac9,pointer:#a3144d \
        --color=marker:#14710a,fg+:#1f1f1f,prompt:#644ac9,hl+:#cb3a2a \
        --color=border:#6c664b,label:#1f1f1f \
        --preview='if [ -d {} ]; then if command -v eza >/dev/null 2>&1; then eza --tree --level=2 {}; else ls -F {}; fi; elif [ -f {} ]; then if command -v bat >/dev/null 2>&1; then bat --color=always --line-range :200 {}; elif command -v batcat >/dev/null 2>&1; then batcat --color=always --line-range :200 {}; else cat {}; fi; fi'"
    set -g hydro_color_pwd $fish_color_cwd
    set -g hydro_color_git $fish_color_quote
    set -g hydro_color_start $fish_color_operator
    set -g hydro_color_prompt $fish_color_end
    set -g hydro_color_duration $fish_color_param
    set -g hydro_color_error $fish_color_error
end


# Added by Antigravity CLI installer
set -gx PATH "/home/lucaspicotti/.local/bin" $PATH
