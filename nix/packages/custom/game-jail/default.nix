# nix/packages/custom/game-jail/default.nix
# Bubblewrap sandbox for Windows games (Faugus / umu / Proton).
#
# Threat model: the game (or its crack) runs as the user, so without a
# sandbox it can read/write all of $HOME (~/.ssh, repos, shell rc → sudo
# hijack). The jail builds a fresh root from scratch and exposes only:
#
#   /nix/store, /etc, /run/current-system, /bin, /usr   read-only
#   /run/opengl-driver{,-32}, /sys                       read-only (GPU)
#   /dev/dri, /dev/nvidia*                               GPU devices
#   $XDG_RUNTIME_DIR/{wayland,pipewire-0,pulse/native}   display + audio
#   ~/.local/share/game-jail/<name>  →  $HOME            private home
#   --ro / --rw PATH                                     extra binds
#
# Deliberately NOT exposed (each one is a sandbox escape):
#   real $HOME, host session D-Bus (systemd1 → run commands outside;
#   the jail gets its own empty bus via dbus-run-session instead),
#   Hyprland IPC socket (dispatch exec), /nix/var (nix-daemon socket),
#   X11 unless --x11 (any X client can keylog every other X client).
#
# Network is unshared unless --net. With no network the X11 abstract
# socket is unreachable too. Without --x11, PROTON_ENABLE_WAYLAND=1 makes
# Wine use its native Wayland driver.
#
# umu-run is itself a buildFHSEnv (bwrap) and Proton adds pressure-vessel;
# both nest fine because the jail keeps unprivileged user namespaces.
#
# Usage: game-jail --name NAME [--net] [--x11] [--ro PATH]... [--rw PATH]...
#                  -- COMMAND [ARGS...]
{ writeShellApplication, bubblewrap, coreutils, dbus }:

writeShellApplication {
  name = "game-jail";
  runtimeInputs = [ bubblewrap coreutils ];
  text = ''
    usage() {
      echo "usage: game-jail --name NAME [--net] [--x11] [--ro PATH]... [--rw PATH]... -- CMD [ARGS...]" >&2
      exit 2
    }

    name="" net=0 x11=0
    ro=() rw=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --name) name="$2"; shift 2 ;;
        --net)  net=1; shift ;;
        --x11)  x11=1; shift ;;
        --ro)   ro+=("$(realpath -e "$2")"); shift 2 ;;
        --rw)   rw+=("$(realpath -e "$2")"); shift 2 ;;
        --)     shift; break ;;
        *)      usage ;;
      esac
    done
    [ -n "$name" ] && [ $# -gt 0 ] || usage

    run="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR not set}"
    wl="''${WAYLAND_DISPLAY:?WAYLAND_DISPLAY not set}"
    jail_home="''${XDG_DATA_HOME:-$HOME/.local/share}/game-jail/$name"
    mkdir -p "$jail_home"

    args=(
      --unshare-all
      --new-session
      --clearenv

      --ro-bind /nix/store /nix/store
      --ro-bind /etc /etc
      --ro-bind /run/current-system /run/current-system
      --ro-bind-try /run/opengl-driver /run/opengl-driver
      --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
      --ro-bind /bin /bin
      --ro-bind /usr /usr
      --ro-bind /sys /sys
      --proc /proc
      --dev /dev
      --dev-bind-try /dev/dri /dev/dri
      --tmpfs /tmp

      --dir "$run"
      --chmod 0700 "$run"
      --bind "$run/$wl" "$run/$wl"
      --bind-try "$run/pipewire-0" "$run/pipewire-0"
      --bind-try "$run/pulse/native" "$run/pulse/native"

      --bind "$jail_home" "$HOME"
      --chdir "$HOME"

      --setenv HOME "$HOME"
      --setenv USER "$USER"
      --setenv LOGNAME "$USER"
      --setenv PATH "$PATH"
      --setenv XDG_RUNTIME_DIR "$run"
      --setenv WAYLAND_DISPLAY "$wl"
      --setenv XDG_SESSION_TYPE wayland
      --setenv GAME_JAIL "$name"
    )

    for dev in /dev/nvidia*; do
      [ -e "$dev" ] && args+=(--dev-bind "$dev" "$dev")
    done

    # Pass-through of harmless session/GPU variables, only when set.
    for var in LANG LC_ALL LOCALE_ARCHIVE TZDIR XDG_CURRENT_DESKTOP \
               XDG_DATA_DIRS XDG_CONFIG_DIRS XCURSOR_THEME XCURSOR_SIZE \
               GBM_BACKEND __GLX_VENDOR_LIBRARY_NAME LIBVA_DRIVER_NAME \
               WLR_NO_HARDWARE_CURSORS NIXOS_OZONE_WL TERM; do
      if [ -n "''${!var:-}" ]; then
        args+=(--setenv "$var" "''${!var}")
      fi
    done

    [ "$net" = 1 ] && args+=(--share-net)

    if [ "$x11" = 1 ] && [ -n "''${DISPLAY:-}" ]; then
      xsock="/tmp/.X11-unix/X''${DISPLAY#*:}"
      xsock="''${xsock%%.*}"
      args+=(--bind-try "$xsock" "$xsock" --setenv DISPLAY "$DISPLAY")
      if [ -n "''${XAUTHORITY:-}" ] && [ -e "$XAUTHORITY" ]; then
        args+=(--ro-bind "$XAUTHORITY" /tmp/.Xauthority --setenv XAUTHORITY /tmp/.Xauthority)
      fi
    else
      args+=(--setenv PROTON_ENABLE_WAYLAND 1)
    fi

    for p in "''${ro[@]}"; do args+=(--ro-bind "$p" "$p"); done
    for p in "''${rw[@]}"; do args+=(--bind "$p" "$p"); done

    # Private, empty session bus inside the jail: GTK/Faugus get a working
    # D-Bus without reaching the host bus.
    exec bwrap "''${args[@]}" -- ${dbus}/bin/dbus-run-session -- "$@"
  '';
}
