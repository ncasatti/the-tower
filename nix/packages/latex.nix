# nix/packages/latex.nix
# LaTeX toolchain — analysis-math focused, pdflatex engine.
# Zathura viewer is configured separately in utilities.nix.
{ pkgs, ... }:

let
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      # Base distribution — covers amsmath, amssymb, amsfonts,
      # mathtools, amsthm, microtype, beamer, hyperref, geometry.
      scheme-medium

      # Build automation
      latexmk

      # Math-analysis extras
      # \mathscr (mathrsfs) ya viene incluido vía collection-mathscience en scheme-medium
      physics     # bra-ket, derivative shortcuts
      siunitx     # SI units formatting

      # Diagrams
      tikz-cd     # commutative diagrams
      pgf         # TikZ base

      # Bibliography
      biber
      biblatex

      # Quality of life
      standalone  # compilable snippets / embedded figures
      preview     # preview.sty — required by standalone's [preview] option,
                  # used by snacks.image's LaTeX-math template to render inline
                  # math as cropped images in markdown. Without it pdflatex
                  # fails silently (convert.notify=false) and math never renders.
      enumitem    # configurable lists

      # md2pdf corporate style (custom/md2pdf/style.tex)
      tcolorbox   # code / metadata / callout panels
      tikzfill    # tcolorbox skins dependency
      pdfcol      # tcolorbox breakable dependency
      lastpage    # "Página N de M" footer
      inconsolata # monospace for code (zi4)
      ;
  };
in
{
  # tex: the LaTeX toolchain (above).
  # ghostscript: ImageMagick's delegate for rasterizing PDF → PNG. Required by
  # snacks.image's math pipeline (pdflatex → PDF → magick/gs → PNG). Without
  # `gs`, math compiles to PDF but magick fails ("gs: command not found") and
  # the equation never becomes a displayable image.
  # md2pdf: markdown → PDF CLI (pandoc + this same `tex`); also backs nvim's
  # <leader>mp / <leader>mE (nvim/lua/util/md-preview.lua).
  home.packages = [
    tex
    pkgs.ghostscript
    (pkgs.callPackage ./custom/md2pdf { inherit tex; })
  ];
}
