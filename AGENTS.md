# OpenCode Agent Instructions

This repository ("The Tower") is a declarative, modular Nix configuration for a four-target NixOS deployment: `notebook`, `main`, `server`, and `wsl`. All four are `nixosConfigurations` in `flake.nix` — there is no Home-Manager-standalone / Arch target.

## Architecture & Boundaries
- **`notebook` target**: NixOS system configuration. Entry point: `nix/hosts/notebook/default.nix`.
- **`main` target**: NixOS system configuration (NVIDIA GPU, secondary HDD mounted at `/mnt/data`). Entry point: `nix/hosts/main/default.nix`. Host-specific modules: `nvidia.nix`, `storage.nix`.
- **`server` target**: NixOS system configuration (headless infra: DNS + VPN; also runs HTPC services via `htpc.nix`). Entry point: `nix/hosts/server/default.nix`.
- **`wsl` target**: NixOS-WSL configuration for Windows-side dev. Entry point: `nix/hosts/wsl/default.nix`. See `docs/nixos-wsl.md`.
- **Per-host Home Manager**: each host imports `nix/hosts/<target>/home.nix`, which pulls in the shared Home Manager modules under `nix/home/` (`dotfiles.nix` holds the app-config symlink table) **and** the shared system modules under `nix/modules/` (audio, services, kanata, tailscale, security, docker, fish, syncthing, …).
- **Packages**: Categorized in `nix/packages/` (`cli.nix`, `dev.nix`, `languages.nix`, `wayland.nix`, `appearance.nix`, `audio.nix`, `utilities.nix`, `nvim.nix`, `ai.nix`, …) plus `custom/` for derivations not in nixpkgs.
- **Secrets**: Encrypted secrets live as `.age` files under `nix/home/secrets/`, imported via `nix/home/secrets.nix`. The agenix integration is currently dormant (import commented out in every host's `home.nix`).
- **Storage on `main`**: Secondary HDD `WDC WD10SPZX` (1 TB, SMR, 5400 RPM) mounted at `/mnt/data` via `nix/hosts/main/storage.nix` using `/dev/disk/by-id/ata-WDC_WD10SPZX-21Z10T0_WD-WX61A773DN64-part1` (hardware-stable across reboot order). Mount options: `noatime`, `lazytime`, `commit=60`, `errors=remount-ro`. Owned `flyn:users 0750`. Used for bulk personal storage (photos, videos, static files, occasional Android SDK, old projects). **Not** for build outputs or random-write-heavy workloads.
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
- **Deploy to NixOS (`wsl`)**:
  ```bash
  sudo nixos-rebuild switch --flake .#wsl
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

### Managing Secrets (legacy: dormant — not currently active)
1. Edit `nix/home/secrets/secrets.nix` to declare a secret (note: this file's import is currently commented out in every host's `home.nix`).
2. Encrypt with agenix: `agenix -e nix/home/secrets/<name>.age`.
3. Re-enable the `nix/home/secrets.nix` import in the target host's `home.nix`, then reference via `config.age.secrets.<name>.path`.
