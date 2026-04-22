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
      "text/html" = [ "zen.desktop" ];
      "x-scheme-handler/http" = [ "zen.desktop" ];
      "x-scheme-handler/https" = [ "zen.desktop" ];
      "x-scheme-handler/about" = [ "zen.desktop" ];
      "x-scheme-handler/unknown" = [ "zen.desktop" ];

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
