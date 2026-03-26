# ====================
# Package Management Aliases
# ====================
# Pacman, paru, yay, and flatpak shortcuts

# Pacman
abbr -a upall topgrade
abbr -a search 'sudo pacman -Qs'
abbr -a remove 'sudo pacman -Rs'
abbr -a install 'sudo pacman -S'
abbr -a linstall 'sudo pacman -U'
abbr -a update 'sudo pacman -Syyu'
abbr -a clrcache 'yay -Scc'
abbr -a orphans 'sudo pacman -Rns (pacman -Qtdq)'
abbr -a akring 'sudo pacman -Sy archlinux-keyring --noconfirm'
abbr -a unlock 'sudo rm /var/lib/pacman/db.lck'

# Paru
abbr -a pget 'paru -S'
abbr -a prem 'paru -R'
abbr -a paruskip 'paru -S --mflags --skipinteg'

# Yay
abbr -a yget 'yay -S'
abbr -a yrem 'yay -R'
abbr -a yayskip 'yay -S --mflags --skipinteg'

# Flatpak
abbr -a fpup 'flatpak update'
