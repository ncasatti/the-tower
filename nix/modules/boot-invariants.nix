# nix/modules/boot-invariants.nix
# NixOS-level assertion: catch a silent brick of stage 1 at evaluation time.
#
# A single `lib.mkForce` on `fileSystems.<x>.options` is enough to drop the
# `x-initrd.mount` flag that nixpkgs injects for every boot-critical
# filesystem (nixos/modules/tasks/filesystems.nix:229-244, where the option
# list is built with mkMerge). Without that flag, `systemd-fstab-generator`
# skips the entry inside the initrd, `sysroot.mount` is never created, and
# `initrd-find-nixos-closure` runs against an empty `/sysroot` and fails;
# `emergency.target` is queued and the transaction is poisoned — entering the
# correct LUKS passphrase afterwards cannot rescue the boot.
# `nix flake check` does not exercise stage 1; without this assertion the
# regression is invisible until the next cold boot.
#
# This module fires at evaluation time and turns the silent brick into a
# build error that names the field. See boot-lockout-postmortem.md §3 and
# §10.3 for the full mechanism.

{ config, lib, utils, ... }:

{
  assertions = [
    {
      # Mirror nixpkgs's own predicate (`nixos/lib/utils.nix:67`):
      #   fsNeededForBoot = fs: fs.neededForBoot || elem fs.mountPoint pathsNeededForBoot
      # where `pathsNeededForBoot` includes "/", "/nix", "/nix/store", "/var",
      # "/var/log", "/var/lib", "/var/lib/nixos", "/etc", "/usr". Note that
      # `/` is in the list — that's why the original bug was a brick even
      # though `fs.neededForBoot` was `false` in every hardware-configuration.
      assertion = lib.all
        (fs: !(utils.fsNeededForBoot fs) || lib.elem "x-initrd.mount" fs.options)
        (lib.attrValues config.fileSystems);
      message = ''
        A boot-critical filesystem is missing the `x-initrd.mount` option.
        Most likely cause: `lib.mkForce` was applied to `fileSystems.<x>.options`
        and replaced the mkMerge that nixpkgs uses to inject that flag.
        Edit the option list at its source (e.g. `hardware-configuration.nix`)
        instead. See boot-lockout-postmortem.md §3.1 for the mechanism.
      '';
    }
  ];
}
