# nix/home/moonlight.nix
# HTPC client: Moonlight (moonlight-qt) pairs with the Sunshine host running on
# `the-grid-server`. Hosts that import this module get the binary AND the
# versioned config in one go.
#
# --- Config hygiene ---
# moonlight/Moonlight.conf is committed WITHOUT the client `certificate=`/`key=`
# pair (those are per-host and regenerated on the first launch). The public
# server certificate under [hosts]/1\srvcert IS kept — it's how Moonlight
# recognizes the server on subsequent boots.
#
# Pairing flow after a fresh install:
#   moonlight pair <server-hostname>      # emits a PIN on stdout
#   browse https://<server>:47990         # enter PIN on the Sunshine UI
# After the first pairing, Moonlight persists it under [hosts]/1\… and you
# won't need to re-pair even if the client cert/key rotate.

{ pkgs, ... }:

{
  home.packages = [
    pkgs.moonlight-qt
  ];

  home.file = {
    ".config/Moonlight Game Streaming Project".source = ../../moonlight;
  };
}
