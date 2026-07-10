"""Production merge: bold `.bold` alternates for ALL word-forming glyphs.

Covers every glyph in the Regular that (a) has a Unicode below the PUA icon
range, (b) is a Letter (category L*) or decimal Digit (Nd), and (c) has a
counterpart in the synthesized Bold. This pulls in Latin accents (áéíóúüñ …),
so Spanish words shape correctly instead of breaking at the accent.

Family/style stay "3270 Nerd Font Mono" Regular so the bionic face REPLACES the
plain Regular of the same family — bionic everywhere, no kitty.conf change, and
the existing Bold face keeps real-bold working.

Usage: fontforge -script merge_prod.py <regular.ttf> <bold.ttf> <out_base.ttf> <pairs.txt>
"""
import fontforge
import unicodedata
import sys

reg_path, bold_path, out_path, pairs_path = sys.argv[1:5]
family = sys.argv[5] if len(sys.argv) > 5 else "3270 Nerd Font Mono"

reg = fontforge.open(reg_path)
bold = fontforge.open(bold_path)


def is_word_glyph(u):
    if u < 0x20 or u > 0x2BFF:      # skip control + PUA icons (Nerd glyphs)
        return False
    cat = unicodedata.category(chr(u))
    return cat[0] == "L" or cat == "Nd"


pairs = []
for g in reg.glyphs():
    u = g.unicode
    if u == -1 or not is_word_glyph(u) or not g.isWorthOutputting():
        continue
    if u not in bold:
        continue
    regname = g.glyphname
    boldname = regname + ".bold"
    w = g.width

    bold.selection.select(("unicode", None), u)
    bold.copy()
    ng = reg.createChar(-1, boldname)
    reg.selection.select(boldname)
    reg.paste()
    ng.width = w
    pairs.append((regname, boldname))

print("merged %d word-glyph alternates" % len(pairs))

# Preserve the monospace signal fontconfig/kitty require.
p = list(reg.os2_panose)
p[0] = 2
p[3] = 9
reg.os2_panose = tuple(p)

# Distinct family so it coexists with the plain Regular (no fontconfig
# collision) and toggling is a one-line kitty.conf font_family swap.
reg.familyname = family
reg.fullname = family
reg.fontname = family.replace(" ", "") + "-Regular"
for key, val in (
    ("Family", family),
    ("SubFamily", "Regular"),
    ("Fullname", family),
    ("Preferred Family", family),
    ("Preferred Styles", "Regular"),
):
    reg.appendSFNTName("English (US)", key, val)

reg.generate(out_path)
print("wrote", out_path)

with open(pairs_path, "w") as fh:
    for r, b in pairs:
        fh.write("%s %s\n" % (r, b))
print("wrote %d pairs -> %s" % (len(pairs), pairs_path))
