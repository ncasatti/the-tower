# nix/modules/docker.nix
# Global Docker configuration shared across hosts.

{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;  # start on demand, not at boot

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  users.users.flyn.extraGroups = [ "docker" ];
}
