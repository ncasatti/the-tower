# Kanata — Keyboard Remapper (WIP)

**Status:** scaffolded, opt-in disabled while iterating  
**Last updated:** 2026-07-09

## Goal

Replace the Linux-only `keyd` remapper with a cross-platform alternative that
keeps the same workflow and can later be shared with Windows. Kanata was
selected — it has an official NixOS module, live reload, and an expressive
config format that supports nested layers and one-shots.

> **Not replacing keyd today.** This is the install scaffold + first
> architecture pass. The opt-in is currently `false` on all hosts; keyd
> stays active. Iterate here, then enable when stable.

## Architecture

The config lives at `kanata/kanata.kbd` and is consumed by the opt-in module
`nix/modules/kanata.nix`. Each host imports the module and toggles
`the-grid.kanata.enable`.

Two leader keys, two interaction models:

- **`space`** (`tap-hold-release 200 200`) — `menu-fast` hold layer for
  ergonomic, fast shortcuts (arrows, edit, esc/tab, home row mods, tmux
  leader).
- **`capslock`** (`one-shot 500`) — `menu-command` command palette that opens
  a tree of sub-menus for less-frequent actions.

### Sub-menus (entered via `caps + <letter>`)

| Key | Sub-menu | Purpose |
|-----|----------|---------|
| `f` | `menu-file` | File operations (find, save, open, recent, new) |
| `b` | `menu-buffer` | Editor buffer management (next, prev, delete, close) |
| `w` | `menu-window` | Hyprland window management (workspaces, focus, cycle) |
| `s` | `menu-symbols` | Full symbol set (preserves the old `[symbols]` layer) |
| `t` | `menu-tmux` | Extended tmux commands (split, rename, detach, etc.) |
| `l` | `menu-launchers` | App launchers (browser, terminal, code, obsidian) |
| `n` | `menu-num` | f-keys, numbers, operators (port from `[num]` layer) |
| `o` | `menu-obsidian` | Obsidian shortcuts (preserved for testing) |
| `?` | `menu-help` | Layer info placeholder |

Each sub-menu is activated as a one-shot from `menu-command`, so the flow
is `caps + <menu> + <action>` — three keystrokes, no hold.

## Nix integration

The module (`nix/modules/kanata.nix`) follows the same opt-in pattern as
other shared modules in `nix/modules/`:

```nix
imports = [ ... ../../modules/kanata.nix ... ];
the-grid.kanata.enable = true;
```

The NixOS module is hardened by default (`DynamicUser`,
`SupplementaryGroups = input + uinput`, full `SystemCallFilter`, etc.) — no
extra setup is needed.

## Key decision: `layer-toggle` vs `overload`

Keyd's `overload(navbar, space)` auto-deactivates the layer when the key is
released. **Kanata has no equivalent.** The closest is `layer-toggle`, which
is a *toggle*, not a hold.

The current `.kbd` uses:

```lisp
spc (tap-hold-release 200 200 spc (layer-toggle menu-fast))
```

Behavior:
- **Quick tap** of `space` → emits `spc`
- **Hold** of `space` → toggles `menu-fast` **on** (stays on after release)
- **Tap** of `space` again → toggles `menu-fast` off

This is the main UX change from keyd. If the toggle-after-release is too
disruptive in daily use, future options include: (a) two physical keys
(one for tap, one for hold), (b) a more complex sequence, or (c) waiting
for kanata to add a `hold-only` layer activation mode.

## Próximos pasos

1. Re-enable opt-in on `main` after finalizing the action list
2. Tune placeholder actions in `menu-file` / `menu-buffer`
3. Verify the `layer-toggle` UX is tolerable in daily use; if not, restructure
4. Port the same `kanata.kbd` to Windows once NixOS side is solid

## Caveats

- QWERTY key names throughout (Linux keycodes). On Colemak the user presses
  QWERTY positions for home row mods and layer navigation; normal typing
  stays on Colemak via the OS layout.
- Shifted symbols (e.g. `(`, `*`, `_`) must use `S-<base-key>` notation in
  `deflayer` — parentheses are reserved by the parser.
- Validate any edit locally before rebuilding:
  ```bash
  nix shell nixpkgs#kanata --command kanata --check --cfg kanata/kanata.kbd
  ```
  The NixOS module's `checkPhase` only validates configs passed via the
  `config` option, **not** via `configFile` (which we use for cross-platform
  sync). The `kanata --check` command above is the source of truth.
