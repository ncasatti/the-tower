# nix/modules/gaming.nix
# Windows gaming via Proton. Desktop hosts only (main, notebook).
#
# - Steam: Steam games + non-Steam shortcuts. GE-Proton is offered as a
#   compatibility tool from nixpkgs; it updates with `nix flake update`.
#   Enabling Steam also sets hardware.graphics.enable32Bit (DXVK).
#   NOTE: Steam is NOT jailed yet — pressure-vessel shares $HOME.
# - Faugus Launcher: umu-launcher frontend for Battle.net, EA, Ubisoft and
#   loose .exe installers. Only reachable through game-jail (bubblewrap,
#   see nix/packages/custom/game-jail); the stock unjailed binary and its
#   .desktop entries are intentionally not installed. Two profiles, each
#   with its own private home at ~/.local/share/game-jail/<profile>
#   (Faugus config, umu runtime, Proton builds, prefixes):
#
#     faugus-trusted    network + X11. Official launchers (Battle.net).
#     faugus-untrusted  offline, Wayland-only (Wine Wayland driver),
#                       sees /mnt/data/linux-games read-write. Anything
#                       not from an official store.
#
#   faugus-<profile> [JAIL FLAGS...] [-- FAUGUS ARGS...], e.g.:
#     faugus-untrusted --ro /mnt/iso          # install from a mounted ISO
#     faugus-untrusted --net                  # one-off: Proton/runtime download
#     faugus-trusted -- --game battlenet      # game shortcut (.desktop Exec)
# - gamemode: CPU governor / scheduling boost. Unreachable from the jail
#   (needs the host session D-Bus; the jail only has a private one).

{ pkgs, ... }:

let
  game-jail = pkgs.callPackage ../packages/custom/game-jail { };
  faugus = pkgs.faugus-launcher;
  icon = "${faugus}/share/icons/hicolor/scalable/apps/io.github.Faugus.faugus-launcher.svg";

  profiles = {
    trusted = {
      flags = [ "--net" "--x11" ];
      label = "Faugus (trusted)";
      comment = "Official launchers: network + X11, private home";
    };
    untrusted = {
      flags = [ "--rw" "/mnt/data/linux-games" ];
      label = "Faugus (untrusted)";
      comment = "Unofficial games: offline, Wayland-only, private home";
    };
  };

  mkLauncher = name: p:
    pkgs.writeShellApplication {
      name = "faugus-${name}";
      runtimeInputs = [ game-jail ];
      # faugus-<name> [JAIL FLAGS...] [-- FAUGUS ARGS...]
      text = ''
        jail=()
        while [ $# -gt 0 ]; do
          if [ "$1" = -- ]; then shift; break; fi
          jail+=("$1"); shift
        done
        exec game-jail --name ${name} ${pkgs.lib.escapeShellArgs p.flags} "''${jail[@]}" \
          -- ${faugus}/bin/faugus-launcher "$@"
      '';
    };

  mkDesktop = name: p:
    pkgs.makeDesktopItem {
      name = "faugus-${name}";
      desktopName = p.label;
      comment = p.comment;
      exec = "faugus-${name}";
      inherit icon;
      categories = [ "Game" ];
    };
in
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages =
    [ game-jail ]
    ++ pkgs.lib.mapAttrsToList mkLauncher profiles
    ++ pkgs.lib.mapAttrsToList mkDesktop profiles;
}
