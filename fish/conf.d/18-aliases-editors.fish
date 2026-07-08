# ====================
# Editor & tool launchers
# ====================
# Text editors and AI CLI shortcuts.
# (Config-editing aliases removed: on NixOS /etc/* is declarative/read-only,
#  and the zsh/i3/pacman/lightdm targets no longer exist here.)

alias vim=nvim
abbr -a v nvim
abbr -a sv 'sudo -E nvim'
abbr -a sn 'sudo nano -T 2'
abbr -a c claude
abbr -a gem gemini
abbr -a o opencode
