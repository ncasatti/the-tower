# SDD — Bionic Reading baked into the 3270 font

## Intent

Bionic Reading (bolding the leading letters of each word to create fixation
anchors) applied **everywhere**, not just inside nvim. The nvim plugin
(`bionic-reading.nvim`) is a highlight-layer transform confined to that editor;
this bakes the effect into the font itself so it reaches every app rendered
through the terminal (kitty, herdr, nvim, opencode/claude-code, `man`, logs,
any TUI).

## Approach

OpenType `calt` (contextual alternates) inside a **new font family**, `3270
Bionic`, derived from `3270 Nerd Font Mono`:

0. The Bold face is synthesized from the pristine Regular with FontForge
   `changeWeight` (3270 ships Regular-only). Weight is `em * FACTOR`, currently
   **FACTOR = 0.028** (`tools/bionic-font/embolden.py`); advance width is
   restored so the monospace grid stays aligned.
1. For every word-forming glyph (Unicode category `L*` or `Nd`, below the PUA
   icon range) a `.bold` alternate is merged in from the synthesized Bold
   outlines. Latin accents (`áéíóúüñ …`) are included so Spanish words shape
   correctly instead of breaking at the accent.
2. `calt` bolds the first **N = 2** letters of each word using the
   "not-preceded-by-a-letter" idiom, robust to shaper run-splitting at spaces:
   - `pos1`: a letter not preceded by any letter → bold (word start).
   - `pos2`: a letter preceded by exactly 1 bold → bold.
   - (generalises to `posK`: a letter preceded by exactly K-1 bolds → bold.)
   - `ignore` guards cap the run at N.
   Each position is a separate lookup (separate pass) so later passes see the
   bolds produced by earlier ones.
3. Icons (Nerd Font PUA) are untouched — no alternates, no calt.
4. Monospace signal preserved: advance width restored to the cell (1080),
   `panose` set to Latin-Text / Monospaced → `fc-scan` reports `spacing=100`,
   which kitty requires or it silently rejects the face.

Verified headlessly with `uharfbuzz` (`hb.shape` with `calt` on) before ship —
see `tools/bionic-font/build_calt.py`.

## Why a distinct family (not an overwrite)

Two faces with the same family+style (`3270 Nerd Font Mono:Regular`) collide in
fontconfig — it would pick one undefined. A distinct `3270 Bionic` family lets
the plain original and the bionic version coexist, so switching is a one-line
`kitty.conf` change with no font rebuild.

Because the family is distinct, a bionic **Bold** face is also shipped
(`IBM-3270NerdMono-BionicBold.ttf`, the synth Bold refamilied) so `bold_font
auto` resolves within the family and real-bold keeps working.

## Files

| File | Role |
|------|------|
| `fonts/IBM-3270NerdMono.ttf` | pristine Regular — **untouched**, the fallback |
| `fonts/IBM-3270NerdMono-Bold.ttf` | synth Bold of the original family (`embolden.py`, factor 0.028) |
| `fonts/IBM-3270NerdMono-Bionic.ttf` | **new** — `3270 Bionic` Regular + calt |
| `fonts/IBM-3270NerdMono-BionicBold.ttf` | **new** — `3270 Bionic` Bold |
| `tools/bionic-font/` | regeneration scripts + README |

## Switch bionic on/off

In `kitty/kitty.conf`, one line:

```conf
font_family family="3270 Bionic"          # bionic everywhere (current default)
# font_family family="3270 Nerd Font Mono" # plain original
```

Then `sudo nixos-rebuild switch --flake .#main`. Both families stay installed,
so flipping the line is the whole toggle.

## Trade-offs / known behaviour

- **Code** gets bionic too (unavoidable — the font is below the app). It is
  mild: code tokens have no spaces, so only the first letters of each token bold
  (`getUserById` → **get**UserById).
- **Fixed N=2**, not classic length-aware ~50%. Short words bold fully. Tunable
  via `build_calt.py`'s last argument; length-aware would need lookahead rules.
- The nvim `bionic-reading.nvim` plugin is now **redundant** for prose and uses a
  different rule (first ~half vs first 2). Candidate for removal in a follow-up.
