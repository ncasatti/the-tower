
# NixOS
abbr -a nr 'sudo nixos-rebuild switch'
abbr -a nr-note 'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#notebook'
abbr -a nr-main 'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#main'

abbr -a nda 'echo "use flake" > .envrc && direnv allow'

abbr -a nd 'nix develop'
abbr -a nd-gev 'nix develop ~/.the-grid/systems/flakes/gev/'

abbr -a nduf 'echo "use flake" > .envrc'

abbr -a ng 'sudo nix-collect-garbage'
abbr -a ngd 'sudo nix-collect-garbage -d'
abbr -a nu 'sudo nixos-rebuild switch --upgrade-all'
