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
    #
    # PINNED to 458cd161 (zen 1.23.2b). Do NOT bump to a newer rev: the
    # upstream flake bumped to 1.23.3b but its sources.json hash
    # (sha256-d9cHic…) does not match the tarball GitHub actually serves for
    # that release tag (sha256-uyBF0+…) — upstream re-uploaded the artifact
    # without refreshing the hash, which fails the build with
    # "hash mismatch in fixed-output derivation". Unpin once youwen5 fixes
    # sources.json.
    #
    # Update flow (when that happens):
    #   git ls-remote https://github.com/youwen5/zen-browser-flake HEAD
    #   → replace the rev below → nix flake update zen-browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake/458cd16116c362a5e92d5db6bdc3599e4e8b1f4a";
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

    antigravity.url = "github:Hy4ri/antigravity-flake"; 

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
      url = "github:ogulcancelik/herdr?ref=v0.9.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hermes Agent (NousResearch): single-user Python agent framework.
    # Built with uv2nix from source; upstream ships NO cachix, so the first
    # build compiles locally. Intentionally NOT following nixpkgs — the uv.lock
    # wheels are pinned and tested against Hermes's own nixpkgs (same rationale
    # as claude-code above). Exposes packages + overlay + nixosModules +
    # homeManagerModules. Update flow:
    #   1) bump ?ref= below to the new tag
    #   2) nix flake lock --update-input hermes-agent
    #   3) sudo nixos-rebuild switch --flake .#<host>
    hermes-agent = {
      url = "github:NousResearch/hermes-agent?ref=v0.22.2";
    };

    # NixOS-WSL: run full NixOS as a WSL2 distribution (the `wsl` host).
    # Pinned to the full commit SHA of release tag 2605.7.2 — fetches the
    # tarball directly from codeload (bypasses the rate-limited GitHub API).
    # Update flow: git ls-remote https://github.com/nix-community/NixOS-WSL
    #   → pick the newest release tag's SHA → replace below → nix flake lock.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/72c92b11bb8289e6651c7fef29cc0a885fd6a255";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # pylon: per-repo control interface runtime (own project, not published).
    # LOCAL input: the repo only exists on `main`, so only `main` installs it
    # (nix/hosts/main/home.nix). Inputs are fetched lazily, so the other hosts
    # evaluate fine as long as they don't reference pkgs.pylon. Intentionally
    # NOT following nixpkgs: pylon needs the Go toolchain from its own lock.
    # Update flow:
    #   1) commit in ~/.the-grid/systems/github/pylon
    #   2) nix flake update pylon
    #   3) sudo nixos-rebuild switch --flake .#main
    pylon = {
      url = "git+file:///home/flyn/.the-grid/systems/github/pylon";
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
