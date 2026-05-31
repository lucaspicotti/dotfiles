if status is-interactive
    fish_add_path ~/.local/bin
    fish_add_path ~/go/bin
    fish_add_path ~/.config/composer/vendor/bin

    abbr -a vim nvim

    # Theme configurations (Catppuccin Mocha)
    set -gx BAT_THEME "Catppuccin Mocha"
    
    set -gx FZF_DEFAULT_OPTS " \
        --height=100% \
        --layout=reverse \
        --border \
        --info=inline \
        --prompt='❯ ' \
        --pointer='▶' \
        --marker='✓' \
        --color=bg+:#313244,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
        --color=border:#89b4fa,label:#cdd6f4 \
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
