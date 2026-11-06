# Static LAN addressing for the server.
#
# WHY THIS EXISTS
# ---------------
# The ONT (Huawei HG8245W5, 192.168.100.1) is the only DHCP server on the
# main LAN and it hands out 192.168.100.2-254. The server MUST own a fixed
# address because AdGuard Home runs here and is meant to be the DNS resolver
# for the whole LAN: the ONT's DHCP server is to advertise this address as
# the primary DNS, so if the address moved, DNS for every device on the
# network would break.
#
# WHY nmcli AND NOT A NIX-MANAGED KEYFILE
# ----------------------------------------
# Two constraints push this into a unit that shells out to nmcli:
#
#   1. The repo is PUBLIC on GitHub, so the WiFi PSK cannot be committed.
#      The "Knet" profile therefore stays a runtime artifact in
#      /etc/NetworkManager/system-connections/ (root-owned, 0600) and Nix
#      only owns the addressing of it — never the credential.
#   2. NetworkManager IGNORES keyfiles that are symlinks (verified on this
#      host: a symlinked .nmconnection never appears in `nmcli con show`),
#      which is what environment.etc creates by default. Copying instead
#      (environment.etc mode) would still put the keyfile, PSK included, in
#      the world-readable /nix/store. nmcli writes real files outside it.
#
# WHAT IT DOES
# ------------
# Both media get the SAME address (192.168.100.4). Only one may be up at a
# time — two interfaces with the same address on one LAN is ARP chaos. The
# wired profile is created with autoconnect=no for exactly that reason.
#
# Switchover when the 1 GbE cable to the ONT is plugged:
#   nmcli con down Knet && nmcli con up grid-wired
# and update the ONT DHCP reservation from the WiFi MAC to the Ethernet MAC.
#
# 192.168.100.4 is inside the ONT's dynamic pool, so the ONT must also
# reserve it for this host (or start the pool above it); otherwise it can
# lease the address to another device. The ONT side lives outside this
# repo: see the vault note systems/the-tower/the-tower-sys-network.md.

{ pkgs, ... }:

let
  lan = {
    address = "192.168.100.4";
    prefixLength = 24;
    gateway = "192.168.100.1";
    dns = "192.168.100.1";
  };
in
{
  systemd.services."nm-static-lan" = {
    description = "Pin the server LAN address (${lan.address}) on WiFi and Ethernet";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.networkmanager ];
    environment = {
      NM_LAN_ADDRESS = lan.address;
      NM_LAN_PREFIX = toString lan.prefixLength;
      NM_LAN_GATEWAY = lan.gateway;
      NM_LAN_DNS = lan.dns;
      NM_WIFI_PROFILE = "Knet";
      NM_WIRED_PROFILE = "grid-wired";
      NM_WIRED_IFACE = "enp1s0f1";
    };
    script = "${./nm-static-lan.sh}";
  };
}
