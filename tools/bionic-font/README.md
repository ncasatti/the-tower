# bionic-font — regeneration tooling

Generates the `3270 Bionic` font family: 3270 Nerd Font with Bionic Reading
baked in via OpenType `calt` (the first 3 letters of every word render as a
`.bold` alternate). Applies below the application layer, so it works in every
terminal app — kitty, herdr, nvim, opencode, logs, TUIs — with no per-app
config.

## Input (the only real source)

- `../../fonts/IBM-3270NerdMono.ttf` — pristine Regular. Everything else
  (the Bold, the bionic faces) is derived from it below.

## Regenerate

```bash
cd tools/bionic-font
FAM="3270 Bionic"
FACTOR=0.028   # current bold weight (stroke = em * factor). Bump for bolder.

# 0) synthesize the Bold face from the pristine Regular (3270 ships Regular-only)
nix shell nixpkgs#fontforge --command fontforge -script embolden.py \
  ../../fonts/IBM-3270NerdMono.ttf ../../fonts/IBM-3270NerdMono-Bold.ttf $FACTOR

# 1) merge bold outlines as `.bold` alternates for every word glyph (Latin + digits)
nix shell nixpkgs#fontforge --command fontforge -script merge_prod.py \
  ../../fonts/IBM-3270NerdMono.ttf ../../fonts/IBM-3270NerdMono-Bold.ttf \
  /tmp/base.ttf /tmp/pairs.txt "$FAM"

# 2) compile the bionic `calt` (N=3) and verify shaping with HarfBuzz
nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages(ps:[ps.fonttools ps.uharfbuzz])' \
  --command python3 build_calt.py /tmp/base.ttf /tmp/pairs.txt \
  ../../fonts/IBM-3270NerdMono-Bionic.ttf 3

# 3) refamily the synth Bold as the bionic Bold face
nix shell nixpkgs#fontforge --command fontforge -script rename_bold.py \
  ../../fonts/IBM-3270NerdMono-Bold.ttf \
  ../../fonts/IBM-3270NerdMono-BionicBold.ttf "$FAM"
```

Then `git add fonts/*.ttf && sudo nixos-rebuild switch --flake .#main && fc-cache -f`.

## Tuning

- **Bold weight:** `FACTOR` in step 0. History: 0.04 (too thick) → 0.03 → 0.025
  → **0.028** (current). Higher = heavier fixation letters.
- **Letters bolded per word:** last arg of `build_calt.py` (the `3`). Higher =
  more of each word bold.
