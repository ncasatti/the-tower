
# NixOS
alias rebuild-notebook 'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#notebook'
alias rebuild-main     'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#main'
alias rebuild-server   'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#server'

# Remote deploy: evaluate here, build AND activate on the target over SSH.
# No leading sudo: nixos-rebuild must run as flyn so SSH uses flyn's
# ~/.ssh/config aliases and keys; `--sudo` elevates only on the target.
# --build-host = target because the target's nix-daemon rejects unsigned
# paths built elsewhere (trusted-users = root).
alias rebuild-notebook-remote 'nixos-rebuild switch --flake ~/.the-grid/the-tower#notebook --target-host notebook --build-host notebook --sudo'
alias rebuild-main-remote     'nixos-rebuild switch --flake ~/.the-grid/the-tower#main --target-host grid --build-host grid --sudo'
alias rebuild-server-remote   'nixos-rebuild switch --flake ~/.the-grid/the-tower#server --target-host server --build-host server --sudo'

alias use-flake 'echo "use flake" > .envrc'
alias uf 'echo "use flake" > .envrc'
abbr -a da 'direnv allow'
abbr -a dr 'direnv reload'
abbr -a dc 'rm -rf .direnv/'

abbr -a nd     'nix develop'
abbr -a nd-gev 'nix develop ~/.the-grid/systems/flakes/gev/'

abbr -a ng  'sudo nix-collect-garbage'
abbr -a ngd 'sudo nix-collect-garbage -d'
abbr -a nu  'sudo nixos-rebuild switch --upgrade-all'

alias clean 'sudo nix-collect-garbage -d'
alias clean-env 'rm -rf /nix/var/nix/gcroots/per-user/$USER/* && nix-env --delete-generations old && sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +2 && nix-collect-garbage -d'
alias clean-store 'nix-store --optimise'

alias restart-hyprlock "hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1' && hyprctl --instance 0 'dispatch exec hyprlock'"



