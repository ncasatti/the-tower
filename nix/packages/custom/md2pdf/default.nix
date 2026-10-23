# nix/packages/custom/md2pdf/default.nix
# Markdown → PDF via pandoc + pdflatex. Inverse of pdf2md.
#
# All pandoc configuration lives in a generated defaults file (pandoc
# --defaults), assembled from the sibling sources:
#
#   metadata.yaml  template variables (geometry, lang, …). Loaded as a
#                  metadata file → a document's YAML front matter wins.
#   unicode.tex    Unicode → LaTeX map so pdflatex accepts −, ✓, ✗, …
#   filter.lua     AST fixes (field blocks, breakable inline code).
#
# Style = pandoc's default LaTeX template; tweak via metadata.yaml first,
# then header includes, then filters. Avoid a custom template.
#
# `tex` is injected by latex.nix so the CLI reuses the exact same texlive
# derivation instead of building a second one.
{ writeShellApplication, writeText, pandoc, tex }:

let
  defaults = writeText "md2pdf-defaults.yaml" ''
    # GFM habit: lists right after a paragraph line, no blank line between.
    from: markdown+lists_without_preceding_blankline
    pdf-engine: pdflatex
    standalone: true
    metadata-files:
      - ${./metadata.yaml}
    include-in-header:
      - ${./unicode.tex}
      - ${./style.tex}
    filters:
      - ${./filter.lua}
  '';
in
writeShellApplication {
  name = "md2pdf";
  runtimeInputs = [ pandoc tex ];
  text = ''
    usage() {
      echo "usage: md2pdf [-o OUT.pdf | -d OUT_DIR] FILE.md..." >&2
      echo "  default: <name>.pdf next to each source" >&2
      echo "  style:   override keys of ${./metadata.yaml}" >&2
      echo "           via the document's YAML front matter" >&2
      exit 2
    }

    out="" outdir=""
    while getopts "o:d:h" opt; do
      case "$opt" in
        o) out="$OPTARG" ;;
        d) outdir="$OPTARG" ;;
        *) usage ;;
      esac
    done
    shift $((OPTIND - 1))
    [ $# -ge 1 ] || usage
    if [ -n "$out" ] && [ $# -gt 1 ]; then
      echo "md2pdf: -o only valid with a single input (use -d)" >&2
      exit 2
    fi

    rc=0
    for src in "$@"; do
      if [ -n "$out" ]; then
        pdf="$out"
      else
        base="$(basename "''${src%.*}").pdf"
        pdf="''${outdir:-$(dirname "$src")}/$base"
      fi
      # --resource-path: resolve relative images against the source dir.
      if pandoc --defaults ${defaults} "$src" -o "$pdf" \
            --resource-path="$(dirname "$src")"; then
        echo "$src → $pdf"
      else
        echo "md2pdf: failed: $src" >&2
        rc=1
      fi
    done
    exit "$rc"
  '';
}
