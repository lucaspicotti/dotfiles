# Paleta Dracula (https://draculatheme.com/contribute)
#   bg #282a36  selection #44475a  fg #f8f8f2  comment #6272a4
#   cyan #8be9fd  green #50fa7b  orange #ffb86c  pink #ff79c6
#   purple #bd93f9  red #ff5555  yellow #f1fa8c

export BAT_THEME="Dracula"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6272a4"

# Baseado em https://github.com/dracula/zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6272a4'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[function]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[command]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#50fa7b,italic'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#ffb86c,italic'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ffb86c'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ffb86c'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#bd93f9'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8be9fd'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#8be9fd'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#8be9fd'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#ff5555'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#ff5555'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#ff5555'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff5555'
ZSH_HIGHLIGHT_STYLES[path]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#bd93f9'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=#ff5555'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[default]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[cursor]='standout'
