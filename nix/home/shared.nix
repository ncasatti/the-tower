# nix/home/shared.nix
# Orchestrator: imports all shared Home Manager modules.
# Does NOT contain inline config — only imports.

{ ... }:

{
  imports = [
    ./dotfiles.nix
    ./git.nix
    ./gtk.nix
    ./tmux.nix
    ./activation.nix

    # Package sets
    ../packages/cli.nix
    ../packages/nvim.nix
    ../packages/languages.nix
    ../packages/wayland.nix
    ../packages/appearance.nix
  ];
}
