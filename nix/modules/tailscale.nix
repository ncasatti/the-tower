# nix/modules/tailscale.nix
# Tailscale VPN mesh — shared across all hosts.
# After first deploy, run: sudo tailscale up

{ ... }:

{
  services.tailscale.enable = true;

  # Allow Tailscale's UDP port through the firewall
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts   = [ 41641 ];
  };
}
