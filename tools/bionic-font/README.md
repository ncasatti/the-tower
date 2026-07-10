# bionic-font — regeneration tooling

Generates the `3270 Bionic` font family: 3270 Nerd Font with Bionic Reading
baked in via OpenType `calt` (the first 3 letters of every word render as a
`.bold` alternate). Applies below the application layer, so it works in every
terminal app — kitty, herdr, nvim, opencode, logs, TUIs — with no per-app
config.

## Inputs (already in the repo, untouched)

- `../../fonts/IBM-3270NerdMono.ttf` — pristine Regular (build source).
- `../../fonts/IBM-3270NerdMono-Bold.ttf` — synthesized Bold (outline source).

## Regenerate

```bash
cd tools/bionic-font
FAM="3270 Bionic"

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

- **Letters bolded per word:** last arg of `build_calt.py` (the `3`). Higher =
  more of each word bold.
- **Bold weight:** re-synthesize the Bold source first (see the embolden step in
  `docs/bionic-font.md`), then regenerate.
