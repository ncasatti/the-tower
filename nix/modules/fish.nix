# nix/modules/fish.nix
# Shared fish shell configuration across all hosts (system scope).
#
# Why system scope and not home-manager: the hand-written fish config
# (config.fish + conf.d/ + functions/) is delivered as dotfiles via
# home/dotfiles.nix, which symlinks the whole ~/.config/fish tree. Enabling
# home-manager's programs.fish would generate ~/.config/fish/config.fish at the
# same path and collide. So plugins land in vendor_conf.d (autoloaded) and
# carapace is wired through interactiveShellInit instead.
# See docs/fish-completion-overhaul.md for the full rationale.

{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    # Drop NixOS' default l/ll/ls aliases; the user defines these in conf.d.
    shellAliases = {
      l  = null;
      ll = null;
      ls = null;
    };

    # carapace: universal completion engine for CLIs that ship no fish
    # completions. Feeds candidates into the normal completion system, which
    # the fzf Tab pager (bind \t fzf_complete) then makes fuzzy-selectable.
    interactiveShellInit = ''
      command -q carapace && carapace _carapace fish | source
    '';
  };

  # Fish plugins autoload from vendor_conf.d / vendor_functions.d:
  #   sponge   — evicts failed / mistyped commands from history, so
  #              autosuggestions stay clean (attacks bad suggestions at the root)
  #   autopair — auto-closes brackets and quotes while typing
  environment.systemPackages = with pkgs; [
    carapace
    fishPlugins.sponge
    fishPlugins.autopair
  ];
}
