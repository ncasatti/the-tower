# ====================
# Utility Aliases
# ====================
# Rclone, wormhole, and miscellaneous utilities

# Rclone
abbr -a r rclone
abbr -a rc 'rclone copy -P'
abbr -a rcon 'rclone config'
abbr -a rn 'rclone ncdu'
abbr -a rs 'rclone sync -P'
abbr -a rl 'rclone ls'
abbr -a rl1 'rclone ls --max-depth=1'
abbr -a rl2 'rclone ls --max-depth=2'
abbr -a rl3 'rclone ls --max-depth=3'
# Mounts
alias mount-books 'mkdir -pv ~/.the-grid/.mounts/books/ && rclone mount gd:/Docs/Books ~/.the-grid/.mounts/books/'

# Wormhole
abbr -a whs 'wormhole send'
abbr -a whr 'wormhole receive'

# Miscellaneous utilities
abbr -a mx 'cmatrix -s -C cyan'
alias wget='wget -c'
abbr -a pingme 'ping -c64 github.com'
abbr -a traceme 'traceroute github.com'
abbr -a x exit
abbr -a myip 'curl -s https://api.ipify.org'
abbr -a t tmux
