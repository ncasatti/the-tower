# ====================
# System Management Aliases
# ====================
# System monitoring and control

# System info
alias free='free -mt'
alias df='df -h'
abbr -a hw 'hwinfo --short'
abbr -a userlist 'cut -d: -f1 /etc/passwd'
abbr -a probe 'sudo -E hw-probe -all -upload'
abbr -a ctl 'sudo systemctl'

# System control
abbr -a sr reboot
abbr -a sp poweroff
abbr -a start-docker 'sudo systemctl start docker'
abbr -a start-bluetooth 'sudo systemctl start bluetooth'
abbr -a start-teamviewer 'sudo teamviewer --daemon start'
