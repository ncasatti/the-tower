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
    # nofail: swap must NEVER be a hard dependency of stage 1 -- see the long
    # note in nix/hosts/main/swap.nix. Critical on this host: it is headless, so
    # an initrd emergency.target here has no console to type a passphrase into
    # and no boot menu to pick an alternative from.
    crypttabExtraOpts = [ "nofail" ];
    # Root LUKS on this host doesn't use allowDiscards/bypassWorkqueues,
    # matching its hardware-configuration.nix style.
  };
}