# nix/packages/utilities.nix
# Utility programs managed via home-manager modules.
{pkgs, inputs, ...}: {
  home.packages = with pkgs; [
    # brave
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    mpv
    yt-dlp
    thunderbird
    sioyek
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
