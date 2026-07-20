if status is-interactive
    fish_add_path ~/.local/bin
    fish_add_path ~/go/bin
    fish_add_path ~/.config/composer/vendor/bin

    abbr -a vim nvim
    abbr -a phpunit "/home/lucaspicotti/phpunit-9.phar"

    # Theme configurations (Everforest Dark)
    set -gx BAT_THEME "gruvbox-dark"
    
    set -gx FZF_DEFAULT_OPTS " \
        --height=100% \
        --layout=reverse \
        --border \
        --info=inline \
        --prompt='❯ ' \
        --pointer='▶' \
        --marker='✓' \
        --color=bg+:#343f44,spinner:#a7c080,hl:#e67e80 \
        --color=fg:#d3c6aa,header:#e67e80,info:#83c092,pointer:#83c092 \
        --color=marker:#dbbc7f,fg+:#d3c6aa,prompt:#a7c080,hl+:#e67e80 \
        --color=border:#3d484d,label:#d3c6aa \
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
