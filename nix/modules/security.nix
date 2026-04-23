# nix/modules/security.nix
# Global security settings shared across all hosts.

{ ... }:

{
  security.sudo.wheelNeedsPassword = false;
}
