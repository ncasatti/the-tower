# nix/modules/wifi-no-powersave.nix
# Disable Wi-Fi power saving on hosts that stream over the LAN.
#
# Notebook chipsets ship with power_save ON (kernel/driver default): the NIC
# dozes between bursts and the AP buffers packets until the next beacon,
# adding 100-200ms latency spikes on an otherwise <10ms link. That is fatal
# for the hypr-rdp stream (max 3 unacknowledged frames in flight — every
# spike freezes the video).
#
# NetworkManager's `wifi.powersave` knob does NOT apply with the iwd backend,
# and iwd exposes no power-save setting of its own, so pin it at the nl80211
# level via udev. The rule re-fires whenever the interface (re)appears, so it
# survives reboots, rmmod/modprobe and interface renames. Backend-agnostic:
# works the same under NetworkManager+iwd or pure iwd.
#
# Imported by: server (RDP source), main (RDP client). The portable notebook
# is deliberately excluded — power save is battery life there.

{ pkgs, ... }:

{
  # `iw` also useful interactively: `iw dev <wlan> get power_save`
  environment.systemPackages = [ pkgs.iw ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
  '';
}
