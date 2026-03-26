# ====================
# File Operations Aliases
# ====================
# Enhanced file management commands

# Better ls - prefer exa, fallback to eza
if command -q exa
    # alias ls='exa --git --icons --color=always --group-directories-first -1'
    alias l='exa -T -L 1 --icons --color=always --group-directories-first'
    alias la='exa -T -L 1 --icons --color=always --group-directories-first --absolute --hyperlink'
    alias ll='exa -l --icons --color=always --group-directories-first'
    alias ls='exa -lah --icons --color=always --group-directories-first'
    alias l1='exa -T -L 2 --icons --color=always --group-directories-first'
    alias l2='exa -T -L 3 --icons --color=always --group-directories-first'
else if command -q eza
    alias ls='eza -al --git --icons --color=always --group-directories-first'
    alias la='eza -a --color=always --group-directories-first'
    alias ll='eza -l --color=always --group-directories-first'
    alias l='eza -lah --color=always --group-directories-first'
    alias l1='eza -T -L 1 --color=always --group-directories-first'
    alias l2='eza -T -L 2 --color=always --group-directories-first'
end

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
