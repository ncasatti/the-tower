# ====================
# Editor Aliases
# ====================
# Text editors and configuration shortcuts

# Editors
alias vim=nvim
abbr -a v nvim
abbr -a sv 'sudo -E nvim'
abbr -a n 'nano -T 2'
abbr -a sn 'sudo nano -T 2'
abbr -a c claude
abbr -a gem gemini
abbr -a o opencode

# Config editing shortcuts
abbr -a nz 'vim ~/.zshrc && source ~/.zshrc'
abbr -a iz 'vim ~/.config/i3/config'
abbr -a nbashrc 'sudo nano ~/.bashrc'
abbr -a nzshrc 'sudo nano ~/.zshrc'
abbr -a nsddm 'sudo nano /etc/sddm.conf'
abbr -a pconf 'sudo nano /etc/pacman.conf'
abbr -a mkpkg 'sudo nano /etc/makepkg.conf'
abbr -a ngrub 'sudo nano /etc/default/grub'
abbr -a smbconf 'sudo nano /etc/samba/smb.conf'
abbr -a nlightdm 'sudo $EDITOR /etc/lightdm/lightdm.conf'
abbr -a nmirrorlist 'sudo nano /etc/pacman.d/mirrorlist'
abbr -a nsddmk 'sudo $EDITOR /etc/sddm.conf.d/kde_settings.conf'
