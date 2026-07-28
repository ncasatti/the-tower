# nix/hosts/server/swap.nix
# Initrd must open the swap LUKS before systemd can swapon it.
# Without this entry, /dev/mapper/luks-e801fd46-... is never created and
# swap.target fails with a "dependency" timeout at every boot (~90s wait).
# Root cause: hardware-configuration.nix declares swapDevices but the
# corresponding boot.initrd.luks.devices entry was never added.
{ config, lib, ... }:
{
  boot.initrd.luks.devices."luks-e801fd46-c89a-4dab-97ab-72ecdf46c786" = {
    device = "/dev/disk/by-uuid/e801fd46-c89a-4dab-97ab-72ecdf46c786";
    # Root LUKS on this host doesn't use allowDiscards/bypassWorkqueues,
    # matching its hardware-configuration.nix style.
  };
}