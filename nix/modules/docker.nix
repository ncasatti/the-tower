# nix/modules/docker.nix
# Global Docker configuration shared across hosts.

{ pkgs, ... }:

{
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  users.users.flyn.extraGroups = [ "docker" ];
}
