# OpenCode Agent Instructions

This repository ("The Tower") is a declarative, modular Nix configuration for a three-target NixOS deployment: `notebook`, `main`, and `server`. All three are `nixosConfigurations` in `flake.nix` — there is no Home-Manager-standalone / Arch target.

## Architecture & Boundaries
- **`notebook` target**: NixOS system configuration. Entry point: `nix/hosts/notebook/default.nix`.
- **`main` target**: NixOS system configuration. Entry point: `nix/hosts/main/default.nix`.
- **`server` target**: NixOS system configuration (headless infra: DNS + VPN). Entry point: `nix/hosts/server/default.nix`.
- **Per-host Home Manager**: each host imports `nix/hosts/<target>/home.nix`, which pulls in the shared modules under `nix/home/` (`dotfiles.nix` holds the app-config symlink table).
- **Packages**: Categorized in `nix/packages/` (`cli.nix`, `dev.nix`, `languages.nix`, `wayland.nix`, `appearance.nix`, `audio.nix`, `utilities.nix`, `nvim.nix`, …) plus `custom/`.
- **Secrets**: Managed via `agenix` in `nix/hosts/<target>/secrets/` (legacy — see below).
- **Module docs**: `nvim/README.md`, `hypr/README.md`, `tmux/TMUX_*.md` are the source of truth for those tools; indexed from the root `README.md`.

## Deployment Commands
**CRITICAL**: Do not guess deployment commands. Use these exact commands based on the target:

- **Deploy to NixOS (`notebook`)**:
  ```bash
  sudo nixos-rebuild switch --flake .#notebook
  ```
- **Deploy to NixOS (`main`)**:
  ```bash
  sudo nixos-rebuild switch --flake .#main
  ```
- **Deploy to NixOS (`server`)**:
  ```bash
  sudo nixos-rebuild switch --flake .#server
  ```

## Common Workflows

### Updating Dependencies
```bash
nix flake update
```

### Validating Configuration
```bash
nix flake check
```

### Adding New Packages
1. Edit the appropriate category file in `nix/packages/` (e.g., `cli.nix`).
2. Add the package to the `home.packages` list.
3. Run the deployment command for the target.

### Adding New Dotfiles
1. Create the application config directory in the repository root (e.g., `appname/`).
2. Edit `nix/home/dotfiles.nix` to add the symlink:
   ```nix
   home.file = {
     ".config/appname".source = ../../appname;
   };
   ```
3. Run the deployment command for the target.

### Managing Secrets (legacy: Not using by the moment)
1. Edit `nix/hosts/notebook/secrets/secrets.nix` to define the secret.
2. Encrypt with agenix: `agenix -e nix/hosts/notebook/secrets/secrets.age`
3. Reference in configuration via `config.age.secrets.<name>.path`.
