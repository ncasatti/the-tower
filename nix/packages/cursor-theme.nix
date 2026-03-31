# nix/packages/cursor-theme.nix
# Custom cursor theme package

{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "DeppinDark-cursors";
  src = ../../themes/icons/DeppinDark-cursors;

  installPhase = ''
    mkdir -p $out/share/icons/DeppinDark-cursors
    cp -r . $out/share/icons/DeppinDark-cursors
  '';
}
