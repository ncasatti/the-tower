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
abbr -a rmd 'rm -r'
abbr -a srm 'sudo rm'
abbr -a srmd 'sudo rm -r'
abbr -a cpd 'cp -R'
abbr -a scp 'sudo cp'
abbr -a scpd 'sudo cp -R'
abbr -a rm 'rm -rf'
abbr -a mkfile touch
abbr -a md 'mkdir -p'

# Archive operations
abbr -a tarc 'tar -cavf'
abbr -a untar 'tar -xvf'
abbr -a tarv 'tar -tvf'
