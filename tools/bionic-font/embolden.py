"""Synthesize a Bold face from a Regular monospace TTF.

Emboldens only the TEXT glyphs (Latin, punctuation, symbols, box-drawing) and
deliberately SKIPS the Nerd Font icon range (PUA). Icons stay crisp, the run is
fast, and overlap-resolution errors on complex icon outlines are avoided.

Converts to cubic splines before emboldening (changeWeight is unreliable on
TrueType 2nd-order/quadratic outlines); generate() re-quantises back to TTF.
Advance width is untouched -> monospace grid stays aligned.

Usage: fontforge -script embolden.py <src.ttf> <dst.ttf> [factor]
"""
import fontforge
import sys

src = sys.argv[1]
dst = sys.argv[2]
factor = float(sys.argv[3]) if len(sys.argv) > 3 else 0.04

f = fontforge.open(src)
em = f.em
amount = int(round(em * factor))
print("em=%d  factor=%.3f  stroke=%d units" % (em, factor, amount))

# Cubic outlines -> clean stroke expansion. Reverted to quadratic on generate().
f.is_quadratic = 0


def is_text(u):
    if u < 0x20:
        return False
    if u <= 0x2BFF:          # Latin, punctuation, symbols, arrows, box/blocks
        return True
    return False             # everything above (incl. PUA icons) is skipped


done = skipped = 0
for g in f.glyphs():
    if g.unicode != -1 and is_text(g.unicode) and g.isWorthOutputting():
        w = g.width  # changeWeight widens the advance -> capture & restore
        try:
            g.changeWeight(amount, "auto", 0, 0, "auto")
            done += 1
        except Exception:
            pass
        g.width = w  # restore monospace advance (breaks the grid otherwise)
    else:
        skipped += 1
print("emboldened %d text glyphs, skipped %d (icons/empty)" % (done, skipped))

# --- Preserve the monospace signal fontconfig/kitty rely on ---
# fontconfig reports spacing=MONO only when panose[0]==2 (Latin Text) and
# panose[3]==9 (Monospaced). Regeneration dropped it (icon glyphs have double
# width, so it isn't re-derived), which made kitty reject the face as non-mono.
p = list(f.os2_panose)
print("panose before:", tuple(p))
p[0] = 2  # Latin Text
p[2] = 8  # weight: Bold
p[3] = 9  # proportion: Monospaced
f.os2_panose = tuple(p)
print("panose after: ", f.os2_panose)

# --- Register as the Bold face of the SAME family ---
family = "3270 Nerd Font Mono"
f.familyname = family
f.fullname = family + " Bold"
f.fontname = "3270NerdFontMono-Bold"
f.weight = "Bold"
f.os2_weight = 700
f.macstyle = 1  # bit 0 = bold

for key, val in (
    ("Family", family),
    ("SubFamily", "Bold"),
    ("Fullname", family + " Bold"),
    ("Preferred Family", family),
    ("Preferred Styles", "Bold"),
):
    f.appendSFNTName("English (US)", key, val)

f.generate(dst)
print("wrote", dst)
