# ====================
# File Operations Aliases
# ====================
# Enhanced file management commands

# Better ls - use eza
alias l='eza -T -L 1 --icons --color=always --group-directories-first'
alias la='eza -T -L 1 --icons --color=always --group-directories-first --absolute --hyperlink'
alias ll='eza -l --icons --color=always --group-directories-first'
alias ls='eza -lah --icons --color=always --group-directories-first'
alias l1='eza -T -L 2 --icons --color=always --group-directories-first'
alias l2='eza -T -L 3 --icons --color=always --group-directories-first'

# File management
alias rmd='rm -r'
alias srm='sudo rm'
alias srmd='sudo rm -r'
alias cpd='cp -R'
alias scp='sudo cp'
alias scpd='sudo cp -R'
alias rm='rm -rf'
abbr -a mkfile touch
abbr -a md 'mkdir -p'

# Archive operations
abbr -a tarc 'tar -cavf'
abbr -a tarx 'tar -xvf'
abbr -a tarv 'tar -tvf'
