{
  description = "The Grid - Terminal Sub-system";

  inputs = {
    # Using the unstable branch to access the latest rolling-release packages
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager, strictly tracking the same nixpkgs version
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."flyn" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Pass additional inputs to modules if required
        extraSpecialArgs = { inherit inputs; };

        # The declarative payload module
        modules = [ ./home.nix ];
      };
    };
}
