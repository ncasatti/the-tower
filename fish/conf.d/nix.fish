
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
