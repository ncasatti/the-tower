# nix/home/xdg.nix
# XDG MIME Applications configuration

{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # --- Documents ---
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];

      # --- Web ---
      "text/html" = [ "brave-browser.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];

      # --- Mail ---
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      "message/rfc822" = [ "thunderbird.desktop" ];

      # --- Videos / Media ---
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];

      # --- Images ---
      "image/jpeg" = [ "qimgv.desktop" ];
      "image/png" = [ "qimgv.desktop" ];
      "image/webp" = [ "qimgv.desktop" ];
      "image/gif" = [ "qimgv.desktop" ];
    };
  };
}