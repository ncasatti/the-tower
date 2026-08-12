# nix/packages/utilities.nix
# Utility programs managed via home-manager modules.
{ pkgs, ... }:

let
  # QCAD bundles its own Qt build that lacks the Wayland buffer/shell
  # integration plugins, so the native Wayland backend fails to start.
  # Force the xcb platform plugin to route it through XWayland.
  qcad = pkgs.symlinkJoin {
    name = "qcad-xwayland";
    paths = [ pkgs.qcad ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qcad --set QT_QPA_PLATFORM xcb
    '';
  };
in
{
  home.packages = with pkgs; [
    thunderbird
    zen-browser
    mpv
    ntfs3g
    # brave
    # google-chrome
    # yt-dlp
    # sioyek
    # zoom-us
    # onlyoffice-desktopeditors
    # qcad
    # tidal-hifi: declared per-host now — wrapped (no VA-API) on main, stock
    # elsewhere. GPU env is host-specific, so is this. See ADR-002.
  ];

  programs.zathura = {
    enable = true;

    options = {
      # Match nvim's `clipboard = "unnamedplus"` (system clipboard, not PRIMARY)
      selection-clipboard = "clipboard";

      # Night mode by default
      recolor = true;
      recolor-keephue = true;

      # Open documents fit to window
      adjust-open = "best-fit";
    };

    mappings = {
      # --- Colemak scroll (hjkl → neui) ---
      "u" = "scroll up";
      "e" = "scroll down";
      "n" = "scroll left";
      "i" = "scroll right";

      # --- Page jumps (mirror nvim E/U) ---
      "U" = "scroll full-up";
      "E" = "scroll full-down";

      # --- Half-page (nvim-style <C-u>/<C-e>) ---
      "<C-u>" = "scroll half-up";
      "<C-e>" = "scroll half-down";

      # --- Search next/prev (mirror nvim k/K) ---
      "k" = "search forward";
      "K" = "search backward";

      # --- Misc ---
      "<C-r>" = "reload";
    };
  };
}
