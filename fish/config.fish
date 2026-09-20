if status is-interactive
    fish_add_path ~/.local/bin
    fish_add_path ~/go/bin
    fish_add_path ~/.config/composer/vendor/bin

    abbr -a vim nvim
    abbr -a phpunit "/home/lucaspicotti/phpunit-9.phar"

    # Catppuccin Latte themes
    set -g fish_color_normal 4c4f69
    set -g fish_color_command 1e66f5
    set -g fish_color_param dd7878
    set -g fish_color_keyword 8839ef
    set -g fish_color_quote 40a02b
    set -g fish_color_redirection ea76cb
    set -g fish_color_end fe640b
    set -g fish_color_comment 8c8fa1
    set -g fish_color_error d20f39
    set -g fish_color_selection --background=ccd0da
    set -g fish_color_search_match --background=ccd0da
    set -g fish_color_option 40a02b
    set -g fish_color_operator ea76cb
    set -g fish_color_escape e64553
    set -g fish_color_autosuggestion 9ca0b0
    set -g fish_color_cancel d20f39
    set -g fish_color_cwd df8e1d
    set -g fish_color_user 179299
    set -g fish_color_host 1e66f5
    set -g fish_color_host_remote 40a02b
    set -g fish_color_status d20f39
    set -g fish_pager_color_progress 9ca0b0
    set -g fish_pager_color_prefix ea76cb
    set -g fish_pager_color_completion 4c4f69
    set -g fish_pager_color_description 9ca0b0
    set -gx BAT_THEME "Catppuccin Latte"

    set -gx FZF_DEFAULT_OPTS " \
        --height=100% \
        --layout=reverse \
        --border \
        --info=inline \
        --prompt='❯ ' \
        --pointer='▶' \
        --marker='✓' \
        --color=bg:#eff1f5,bg+:#ccd0da,spinner:#df8e1d,hl:#d20f39 \
        --color=fg:#4c4f69,header:#1e66f5,info:#179299,pointer:#dc8a78 \
        --color=marker:#40a02b,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 \
        --color=border:#bcc0cc,label:#1e66f5 \
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

set -gx CPM_SOURCE_CACHE $HOME/.cache/CPM
