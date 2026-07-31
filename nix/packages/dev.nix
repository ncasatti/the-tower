# nix/packages/dev.nix
# Development tools and utilities
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nurl # Generate Nix fetcher expressions (src hash) from a URL
    postman
    bruno
    # posting
    # postgresql
    dbeaver-bin
    # mariadb.client
    # beekeeper-studio
  ];
}
