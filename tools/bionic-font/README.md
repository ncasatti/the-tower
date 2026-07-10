# bionic-font — regeneration tooling

Generates the `3270 Bionic` font family: 3270 Nerd Font with Bionic Reading
baked in via OpenType `calt` (the first 2 letters of every word render as a
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

# 2) compile the bionic `calt` (N=2) and verify shaping with HarfBuzz
nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages(ps:[ps.fonttools ps.uharfbuzz])' \
  --command python3 build_calt.py /tmp/base.ttf /tmp/pairs.txt \
  ../../fonts/IBM-3270NerdMono-Bionic.ttf 2

# 3) refamily the synth Bold as the bionic Bold face
nix shell nixpkgs#fontforge --command fontforge -script rename_bold.py \
  ../../fonts/IBM-3270NerdMono-Bold.ttf \
  ../../fonts/IBM-3270NerdMono-BionicBold.ttf "$FAM"
```

Then `git add fonts/*.ttf && sudo nixos-rebuild switch --flake .#main && fc-cache -f`.

## Tuning

- **Bold weight:** `FACTOR` in step 0. History: 0.04 (too thick) → 0.03 → 0.025
  → **0.028** (current). Higher = heavier fixation letters.
- **Letters bolded per word:** last arg of `build_calt.py` (the `2`). Higher =
  more of each word bold.
- **Glyph coverage** (which chars get a `.bold` alternate): `is_word_glyph()` in
  `merge_prod.py` — currently Unicode category `L*` or `Nd`, below `0x2BFF` (so
  Nerd icons in the PUA are excluded). Widen the range to cover more scripts.

## Iterating (for a future agent)

**Preview before you ship — never overwrite the real font to test.** Build the
candidate under a THROWAWAY family name and drop it in the user's font dir; they
compare in a one-off kitty window with no rebuild and no commit:

```bash
# build with a distinct family, e.g. "3270 Bionic TEST" (pass it as merge_prod's
# last arg), output to /tmp, then:
cp /tmp/3270BionicTEST.ttf ~/.local/share/fonts/
fc-cache -f ~/.local/share/fonts
# user runs, compares against current, decides:
kitty -o font_family="3270 Bionic TEST" fish -C "printf '%s\n' 'the quick brown fox — canción código'"
```

Only after the user approves: rebuild with `FAM="3270 Bionic"`, write into
`fonts/`, commit, and `rm ~/.local/share/fonts/3270Bionic*TEST*.ttf` to clean up.
The real `3270 Bionic` face is a Home-Manager symlink, so a second file with the
SAME family name collides in fontconfig — that is why previews need a new name.

**Which stages to re-run for which change** (skip the rest):

| Change | Stages |
|--------|--------|
| Bold weight (`FACTOR`) | 0 → 1 → 2 → 3 (weight touches every derived face) |
| Letters per word (N) | 1 → 2 only (Bold source unchanged) |
| Glyph coverage | 1 → 2 (and 3 only if the Bold weight also changed) |

**Verify headlessly** — `build_calt.py` already shapes sample strings with
`uharfbuzz` and prints which glyphs became `.bold`. Confirm the count matches N
(and that accented words don't break) before asking the user to look. Always
check `fc-scan --format "%{spacing}\n"` reports `100`, or kitty rejects the face.
