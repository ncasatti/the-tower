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

# Obsidian sync
abbr -a obsidian-push 'rclone sync ~/Documents/ObsidianVault gd:Docs/ObsidianVault -P'
abbr -a obsidian-get 'rclone sync gd:Docs/ObsidianVault ~/Documents/ObsidianVault -P'
abbr -a obsidian-sync 'rclone bisync ~/Documents/ObsidianVault gd:Docs/ObsidianVault -P'
abbr -a obsidian-resync 'rclone bisync ~/Documents/ObsidianVault gd:Docs/ObsidianVault -P --resync'

# Wormhole
abbr -a whs 'wormhole send'
abbr -a whr 'wormhole receive'

# Miscellaneous utilities
abbr -a br 'xrandr --output eDP --brightness'
abbr -a mx 'cmatrix -s -C cyan'
alias wget='wget -c'
abbr -a pingme 'ping -c64 github.com'
abbr -a cls 'clear && neofetch'
abbr -a traceme 'traceroute github.com'
abbr -a x exit
abbr -a myip 'curl -s https://api.ipify.org'
abbr -a t tmux
