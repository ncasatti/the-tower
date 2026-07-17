
# NixOS
alias rebuild-note   'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#notebook && ~/.the-gridthe-towerhyprscriptssystemrefresh.sh'
alias rebuild-main   'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#main && ~/.the-grid/the-tower/hypr/scripts/system/refresh.sh'
alias rebuild-server 'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#server && ~/.the-gridthe-towerhyprscriptssystemrefresh.sh'

alias use-flake 'echo "use flake" > .envrc'

abbr -a nd     'nix develop'
abbr -a nd-gev 'nix develop ~/.the-grid/systems/flakes/gev/'

abbr -a ng  'sudo nix-collect-garbage'
abbr -a ngd 'sudo nix-collect-garbage -d'
abbr -a nu  'sudo nixos-rebuild switch --upgrade-all'
