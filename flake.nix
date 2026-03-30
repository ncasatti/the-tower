{
  description = "The Grid - Mainframe System & Terminal Sub-system";

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

    # Zen Browser (community flake, not in nixpkgs)
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, agenix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
    in {

      # =======================================================================
      # 1. THE MAINFRAME (NixOS System-Level Configuration for the Notebook)
      # Deployment command: sudo nixos-rebuild switch --flake .#notebook
      # =======================================================================
      nixosConfigurations."notebook" = nixpkgs.lib.nixosSystem {
        inherit system;

        # Pass flake inputs directly to all internal modules
        specialArgs = { inherit inputs; };

        modules = [
          # The core OS configuration
          ./nix/hosts/notebook

          # Inject Home Manager natively as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;

            # Map the 'flyn' user to its declarative environment payload
            home-manager.users.flyn = import ./nix/home/notebook.nix;

            # Pass inputs specifically to Home Manager
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # =======================================================================
      # 2. THE TOWER (User-Level Standalone Configuration for Arch Linux)
      # Deployment command: nix run home-manager/master -- switch --flake .#main
      # =======================================================================
      homeConfigurations."main" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Pass inputs specifically to Home Manager
        extraSpecialArgs = { inherit inputs; };

        # The declarative user payload
        modules = [ ./nix/home/main.nix ];
      };

    };
}
