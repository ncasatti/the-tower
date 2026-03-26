# ====================
# Konfig Management Aliases
# ====================
# Configuration repository management shortcuts

# Konfig manager
# abbr -a k 'python ~/.config/konfig/konfig-manager/manager.py'
abbr -a km 'source /home/ncasatti/Documents/Development/microservices/manager/.venv/bin/activate.fish && cd /home/ncasatti/.config/konfig/manager/ && clingy'
abbr -a kv 'source /home/ncasatti/Documents/Development/microservices/manager/.venv/bin/activate.fish'
abbr -a k 'clingy'

# Konfig sync - push, get, sync, resync
abbr -a kp 'rclone sync -P ~/.config/konfig gd:Docs/Development/Linux/konfig -P --copy-links'
abbr -a kg 'rclone sync -P gd:Docs/Development/Linux/konfig ~/.config/konfig -P --copy-links'
abbr -a ks 'r bisync ~/.config/konfig gd:Docs/Development/Linux/konfig -P --copy-links'
abbr -a krs 'r bisync ~/.config/konfig gd:Docs/Development/Linux/konfig -P --copy-links --resync'
