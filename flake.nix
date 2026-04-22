{
  description = "The Grid - Dual NixOS Mainframe Configuration";

  inputs = {
    # Core NixOS packages (Unstable branch for rolling release updates)
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager input, strictly tracking the same nixpkgs version
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agenix: Encrypted secret management for NixOS
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser (community flake, not in nixpkgs) — disabled until stable
    # zen-browser = {
    #   url = "github:0xc000022070/zen-browser-flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # OpenCode AI CLI (community flake with hourly updates)
    opencode-nix = {
      url = "github:dominicnunez/opencode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Clingy: Context-aware CLI framework
    clingy = {
      url = "github:ncasatti/clingy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, agenix, ... }@inputs:
    {

      # =======================================================================
      # 1. NOTEBOOK (NixOS — portable workstation)
      # Deployment: sudo nixos-rebuild switch --flake .#notebook
      # =======================================================================
      nixosConfigurations."notebook" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./nix/hosts/notebook

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;
            home-manager.users.flyn = import ./nix/hosts/notebook/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # =======================================================================
      # 2. MAIN (NixOS — primary workstation)
      # Deployment: sudo nixos-rebuild switch --flake .#main
      # =======================================================================
      nixosConfigurations."main" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./nix/hosts/main

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;
            home-manager.users.flyn = import ./nix/hosts/main/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

    };
}
