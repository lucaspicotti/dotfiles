if status is-interactive
    fish_add_path ~/.local/bin
    fish_add_path ~/go/bin
    fish_add_path /usr/local/go/bin
    fish_add_path ~/.config/composer/vendor/bin

    abbr -a vim nvim
    abbr -a phpunit "/home/lucaspicotti/phpunit-9.phar"

    # Duskfox (nightfox.nvim) theme
    set -g fish_color_normal e0def4
    set -g fish_color_command 65b1cd
    set -g fish_color_param cdcbe0
    set -g fish_color_keyword c4a7e7
    set -g fish_color_quote a3be8c
    set -g fish_color_redirection eb98c3
    set -g fish_color_end f0a4a2
    set -g fish_color_comment 817c9c
    set -g fish_color_error eb6f92
    set -g fish_color_selection --background=433c59
    set -g fish_color_search_match --background=433c59
    set -g fish_color_option a3be8c
    set -g fish_color_operator eb98c3
    set -g fish_color_escape f083a2
    set -g fish_color_autosuggestion 6e6a86
    set -g fish_color_cancel eb6f92
    set -g fish_color_cwd f6c177
    set -g fish_color_user 9ccfd8
    set -g fish_color_host 569fba
    set -g fish_color_host_remote a3be8c
    set -g fish_color_status eb6f92
    set -g fish_pager_color_progress 6e6a86
    set -g fish_pager_color_prefix eb98c3
    set -g fish_pager_color_completion e0def4
    set -g fish_pager_color_description 6e6a86
    set -gx BAT_THEME "Duskfox"

    set -gx FZF_DEFAULT_OPTS " \
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
