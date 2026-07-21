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

    # Zen Browser (community flake, recommended by NixOS wiki)
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code (community flake, hourly updates from Anthropic npm release).
    # Intentionally NOT following nixpkgs — preserves cachix prebuilt cache hits
    # (claude-code.cachix.org). See nix/modules/nix.nix for the substituter.
    claude-code = {
      url = "github:sadjow/claude-code-nix";
    };

    # Herdr: terminal workspace manager for AI coding agents (tmux-like,
    # agent-aware). Not in nixpkgs; upstream flake exposes packages + overlay.
    # Pinned to tag v0.7.3 — update flow:
    #   1) bump ?ref= below to the new tag
    #   2) nix flake lock --update-input herdr
    #   3) sudo nixos-rebuild switch --flake .#<host>
    herdr = {
      url = "github:ogulcancelik/herdr?ref=v0.7.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL: run full NixOS as a WSL2 distribution (the `wsl` host).
    # Pinned to the full commit SHA of release tag 2605.7.2 — fetches the
    # tarball directly from codeload (bypasses the rate-limited GitHub API).
    # Update flow: git ls-remote https://github.com/nix-community/NixOS-WSL
    #   → pick the newest release tag's SHA → replace below → nix flake lock.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/add6b01c7ca72240046b5d541a74845423f1ee35";
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
          { nixpkgs.overlays = [ (import ./nix/overlays/default.nix { inherit inputs; }).additions ]; }
          ./nix/hosts/notebook

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
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
          { nixpkgs.overlays = [ (import ./nix/overlays/default.nix { inherit inputs; }).additions ]; }
          ./nix/hosts/main

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.flyn = import ./nix/hosts/main/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # =======================================================================
      # 3. SERVER (NixOS — headless infrastructure node: DNS + VPN)
      # Deployment: sudo nixos-rebuild switch --flake .#server
      # =======================================================================
      nixosConfigurations."server" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          { nixpkgs.overlays = [ (import ./nix/overlays/default.nix { inherit inputs; }).additions ]; }
          ./nix/hosts/server

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.flyn = import ./nix/hosts/server/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # =======================================================================
      # 4. WSL (NixOS-WSL — headless host inside a Windows box)
      # Deployment (inside the distro): sudo nixos-rebuild switch --flake .#wsl
      # See docs/nixos-wsl.md
      # =======================================================================
      nixosConfigurations."wsl" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          { nixpkgs.overlays = [ (import ./nix/overlays/default.nix { inherit inputs; }).additions ]; }
          inputs.nixos-wsl.nixosModules.default
          ./nix/hosts/wsl

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.flyn = import ./nix/hosts/wsl/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

    };
}
