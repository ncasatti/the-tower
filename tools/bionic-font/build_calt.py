"""Compile the bionic `calt` into the merged base font, then verify via HarfBuzz.

The rule set bolds the first N letters of each word using the
"not-preceded-by-a-letter" idiom, which is robust whether or not the shaper
splits runs at spaces:

  pos1: a @base NOT preceded by a letter          -> bold   (word start)
  pos2: a @base preceded by exactly one @bold     -> bold
  ...
  posN: a @base preceded by exactly (N-1) @bold   -> bold

Each position is a separate lookup (separate pass) so later passes see the
bolds produced by earlier ones. `ignore` guards cap the run at N.

Usage: python build_calt.py <base.ttf> <pairs.txt> <out.ttf> <N>
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.feaLib.builder import addOpenTypeFeaturesFromString

base_path, pairs_path, out_path, n_str = sys.argv[1:5]
N = int(n_str)

reg_names, bold_names = [], []
with open(pairs_path) as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        r, b = line.split()
        reg_names.append(r)
        bold_names.append(b)

base_cls = "@base = [" + " ".join(reg_names) + "];"
bold_cls = "@bold = [" + " ".join(bold_names) + "];"

lookups = []
for pos in range(1, N + 1):
    backtrack = "@bold " * (pos - 1)
    guard = "@bold " * pos  # one more bold than this position -> already past posN cap
    lines = ["  lookup pos%d {" % pos]
    if pos == 1:
        # Word start: ignore if preceded by ANY letter. Two guards are needed
        # because within this pass the just-bolded initial turns the next
        # letter's backtrack into @bold, while deeper letters are still @base.
        lines.append("    ignore sub @base @base';")
        lines.append("    ignore sub @bold @base';")
        lines.append("    sub @base' lookup toBold;")
    else:
        # cap: if `pos` bolds already precede, this base is past posN -> skip.
        lines.append("    ignore sub %s@base';" % guard)
        lines.append("    sub %s@base' lookup toBold;" % backtrack)
    lines.append("  } pos%d;" % pos)
    lookups.append("\n".join(lines))

fea = """
languagesystem DFLT dflt;
languagesystem latn dflt;

{base}
{bold}

lookup toBold {{
  sub @base by @bold;
}} toBold;

feature calt {{
{lookups}
}} calt;
""".format(base=base_cls, bold=bold_cls, lookups="\n".join(lookups))

print("=== generated .fea ===")
print(fea)

font = TTFont(base_path)
addOpenTypeFeaturesFromString(font, fea)
font.save(out_path)
print("wrote", out_path)

# ---- HarfBuzz verification (headless) ----
import uharfbuzz as hb

with open(out_path, "rb") as fh:
    data = fh.read()
face = hb.Face(data)
hbfont = hb.Font(face)


def shape(text):
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(hbfont, buf, {"calt": True})
    names = [hbfont.glyph_to_string(info.codepoint) for info in buf.glyph_infos]
    return names


print("\n=== shaping (calt on) ===")
for sample in ["hello world", "canción corazón ñandú árbol", "el múltiple",
               "MixedCase código123", "getUserById"]:
    print("%-16s -> %s" % (sample, " ".join(shape(sample))))
