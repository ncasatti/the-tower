
# NixOS
alias rebuild-note   'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#notebook'
alias rebuild-main   'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#main'
alias rebuild-server 'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#server'

alias use-flake 'echo "use flake" > .envrc'

abbr -a nd     'nix develop'
abbr -a nd-gev 'nix develop ~/.the-grid/systems/flakes/gev/'

abbr -a ng  'sudo nix-collect-garbage'
abbr -a ngd 'sudo nix-collect-garbage -d'
abbr -a nu  'sudo nixos-rebuild switch --upgrade-all'

alias clean 'sudo nix-collect-garbage -d'
alias clean-env 'rm -rf /nix/var/nix/gcroots/per-user/$USER/* && nix-env --delete-generations old && sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +2 && nix-collect-garbage -d'
alias clean-store 'nix-store --optimise'

alias restart-hyprlock "hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1' && hyprctl --instance 0 'dispatch exec hyprlock'"



