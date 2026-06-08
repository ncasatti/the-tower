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
      enumitem    # configurable lists
      ;
  };
in
{
  home.packages = [ tex ];
}
