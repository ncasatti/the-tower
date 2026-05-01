# OpenCode Agent Instructions

This repository ("The Tower") is a declarative, modular Nix configuration for a dual-target deployment: NixOS (`notebook` and `main`).

## Architecture & Boundaries
- **`notebook` target**: NixOS system configuration. Entry point: `nix/hosts/notebook/default.nix`.
- **`main` target**: NixOS system configuration. Entry point: `nix/hosts/main/default.nix`.
- **Shared Home Manager**: `nix/home/shared.nix` and `nix/home/dotfiles.nix` (symlinks for app configs).
- **Packages**: Categorized in `nix/packages/` (`cli.nix`, `languages.nix`, `wayland.nix`, `appearance.nix`).
- **Secrets**: Managed via `agenix` in `nix/hosts/notebook/secrets/`.

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
