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
    # nofail: swap must NEVER be a hard dependency of stage 1. Entries generated
    # from boot.initrd.luks.devices land in the initrd crypttab without nofail
    # (nixos/modules/system/boot/luksroot.nix:590-611), which makes them
    # RequiredBy=cryptsetup.target -- any failure there drags the whole boot into
    # emergency.target. The initrd only needs the root device; swap failing
    # should cost a swap.target timeout, not the machine.
    crypttabExtraOpts = [ "nofail" ];
    # Match root LUKS options for consistency:
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}