"""Refamily the synthesized Bold so it becomes the Bold face of the bionic
family. No calt is needed: bold text is already fully bold, so there is no
bionic distinction to draw.

Usage: fontforge -script rename_bold.py <synth_bold.ttf> <out.ttf> <family>
"""
import fontforge
import sys

src, dst, family = sys.argv[1:4]
f = fontforge.open(src)
f.familyname = family
f.fullname = family + " Bold"
f.fontname = family.replace(" ", "") + "-Bold"
f.weight = "Bold"
f.os2_weight = 700
f.macstyle = 1
for key, val in (
    ("Family", family),
    ("SubFamily", "Bold"),
    ("Fullname", family + " Bold"),
    ("Preferred Family", family),
    ("Preferred Styles", "Bold"),
):
    f.appendSFNTName("English (US)", key, val)
f.generate(dst)
print("wrote", dst, "as", family, "Bold")
