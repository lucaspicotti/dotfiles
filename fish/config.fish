if status is-interactive
    fish_add_path ~/.local/bin

    abbr -a vim nvim

    if not set -q SSH_AUTH_SOCK
        ssh-agent -c | source
    end

    ssh-add ~/.ssh/id_ed25519 2>/dev/null

    set -gx FZF_DEFAULT_OPTS "
        --height=100% \
        --layout=reverse \
        --border \
        --preview='
            if test -d "{}"
                eza --tree --level=2 "{}"
            else if test -f "{}"
                bat --color=always --line-range :200 "{}"
            end
        '"

    set -g hydro_color_pwd $fish_color_cwd
    set -g hydro_color_git $fish_color_quote
    set -g hydro_color_start $fish_color_operator
    set -g hydro_color_prompt $fish_color_end
    set -g hydro_color_duration $fish_color_param
    set -g hydro_color_error $fish_color_error
end
