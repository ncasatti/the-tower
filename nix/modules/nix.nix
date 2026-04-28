# nix/modules/nix.nix
# Global Nix daemon settings shared across all hosts.

{ ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size  = 268435456;  # 256MB (default 64MB)
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  nixpkgs.config.allowUnfree = true;
}
