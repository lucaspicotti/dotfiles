# Baseado no tema lambda do oh-my-zsh, com a paleta Dracula.
# λ fica roxo quando o último comando deu certo e vermelho quando falhou.

PROMPT='%(?.%F{#bd93f9}.%F{#ff5555})λ%f %F{#8be9fd}%~/%f $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%F{#ff79c6}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{#ffb86c}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""
