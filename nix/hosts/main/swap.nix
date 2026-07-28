# nix/hosts/main/swap.nix
# Initrd must open the swap LUKS before systemd can swapon it.
# Without this entry, /dev/mapper/luks-005a1c08-... is never created and
# swap.target fails with a "dependency" timeout at every boot (~90s wait).
# Root cause: hardware-configuration.nix declares swapDevices but the
# corresponding boot.initrd.luks.devices entry was never added.
{ config, lib, ... }:
{
  boot.initrd.luks.devices."luks-005a1c08-56f9-4c42-a517-d075adc11615" = {
    device = "/dev/disk/by-uuid/005a1c08-56f9-4c42-a517-d075adc11615";
    # Match root LUKS options for consistency:
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}