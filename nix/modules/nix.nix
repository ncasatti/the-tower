# nix/modules/nix.nix
# Global Nix daemon settings shared across all hosts.

{ ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size  = 268435456;  # 256MB (default 64MB)

    # Prebuilt binary cache for the claude-code community flake.
    extra-substituters = [ "https://claude-code.cachix.org" ];
    extra-trusted-public-keys = [
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  nixpkgs.config.allowUnfree = true;
}
