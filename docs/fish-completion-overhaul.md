# Fish completion & keybinding overhaul

**Status:** implemented (pending `nixos-rebuild switch`)
**Date:** 2026-07-01

## Goal

1. Make the **right arrow** accept a single word of the autosuggestion (not the
   whole thing), without losing in-line cursor navigation.
2. Improve completion quality: universal completions, cleaner history-based
   autosuggestions.

## Key decision: system scope, not home-manager

`programs.fish` and the fish plugins live at the **NixOS system layer**
(`nix/modules/fish.nix`), imported by every host — **not** home-manager.

**Why.** The hand-written fish config (`fish/config.fish`, `fish/conf.d/`,
`fish/functions/`) is delivered as dotfiles by `nix/home/dotfiles.nix`, which
symlinks the whole `~/.config/fish` tree (`recursive = true`). Home-manager's
`programs.fish` generates `~/.config/fish/config.fish` at the same path →
**build collision** (two definitions for one target). Migrating into HM would
require ripping `config.fish` out of the dotfiles and rewriting it as
`interactiveShellInit`. Not worth it.

Consequences of staying at system scope:

- Plugins are installed via `environment.systemPackages` and **autoload from
  `vendor_conf.d`** — no first-class `programs.fish.plugins` list (that's an HM
  feature), but functionally identical.
- carapace is wired via `programs.fish.interactiveShellInit`, not the HM
  `programs.carapace` module.

## Changes

### 1. Right-arrow binding — `fish/config.fish`

Conditional binding on the right arrow (`\e[C` / `\eOC`):
- **cursor at end of line** → `forward-word` (accept ONE word of the suggestion)
- **cursor mid-line** → `forward-char` (normal single-char move)

`Ctrl-F` / `End` still accept the whole suggestion. `Alt-→` unchanged.
Tab is left alone — it is already bound to `fzf_complete`.

### 2. Shared module — `nix/modules/fish.nix` (new)

- Consolidates the three previously-divergent `programs.fish` blocks
  (`main`/`notebook` nulled `l/ll/ls`; `server` did not) into one.
- `carapace` — universal completion engine; candidates flow into the fzf pager.
- `fishPlugins.sponge` — drops failed/mistyped commands from history so
  autosuggestions stay clean (root-cause fix for bad suggestions).
- `fishPlugins.autopair` — auto-closes brackets/quotes.

Imported by `main`, `notebook`, `server`; inline `programs.fish` blocks removed.

## Deferred (next step)

- **`alias` → `abbr` migration.** ~10 alias files under `fish/conf.d/`.
  Abbreviations expand inline (real command in history, visible before running).
  To be done as a curated pass, not a blind sweep.

## Gotcha found during rollout: `fish_variables` was committed

The first `switch` spewed `Read-only file system (os error 30)` while trying to
write `fish_variables`. Root cause: **`fish/fish_variables` was git-tracked**, so
`dotfiles.nix` symlinked it read-only into the nix store. `fish_variables` is
*mutable runtime state* (where fish persists `set -U` universal variables), not
config. The new plugins (autopair/sponge) do `set -U` on first load → write to a
read-only path → `EROFS`.

Fix: `git rm fish/fish_variables` + `.gitignore` it. fish now owns it as a normal
writable file in `~/.config/fish/`. The only var it held (`fish_user_paths` →
opencode bin) is redundant — `config.fish:8` re-adds it via `fish_add_path`.

**Rule:** never commit `fish_variables` / `fish_history` — runtime state, not config.

## Gotcha #2: autopair steals the Tab binding

After the switch, `bind \t fzf_complete` (config.fish) stopped triggering fzf —
Tab fell back to native completion. Root cause: **`fishPlugins.autopair`
unconditionally rebinds `\t` → `_autopair_tab`** via its own
`--on-variable fish_key_bindings` handler. That handler fires during interactive
init *after* `config.fish` runs, so it clobbers the user's Tab binding.
(`_autopair_tab` ends in `commandline --function complete` = the native pager,
now carapace-powered — which is exactly what the user saw.)

Not reproducible with `fish -ic` because there `$fish_key_bindings` stays unset,
so autopair's handler `return`s early. It only bites in a full interactive shell.

Fix: re-assert the binding from *our own* `--on-variable fish_key_bindings`
handler in `config.fish`. Event handlers fire in registration order; ours is
defined after autopair's (autopair loads from vendor_conf.d, before config.fish),
so ours runs last and wins. Binds `\t` in both `default` and `insert` modes.

**Rule:** a plugin's `--on-variable fish_key_bindings` hook can override any
`bind` from config.fish. To beat it, rebind from your own such hook (registered
later), not from a bare `bind` line.

## Apply

```bash
git add nix/modules/fish.nix fish/config.fish .gitignore   # flake only sees tracked files
git rm --cached fish/fish_variables 2>/dev/null            # (already done)
sudo nixos-rebuild switch --flake .#main
```
