# nix/home/bash.nix
# Bash as login shell with fish redirect for interactive sessions.
# Keeps non-interactive SSH probes (Hermes Desktop) running under bash
# while giving the user fish on terminals. See NousResearch/hermes-agent#80625.

{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    initExtra = ''
      # Launch fish for interactive sessions only
      if [[ $- == *i* && -z "$BASH_FISH_REDIRECTED" ]]; then
        export BASH_FISH_REDIRECTED=1
        exec ${pkgs.fish}/bin/fish
      fi
    '';
  };
}
