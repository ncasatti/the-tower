# nix/modules/journald.nix
# Limit systemd journal size. Default SystemMaxUse is 4 GiB or 15% of
# filesystem — too generous for our small root partitions. 400 MiB
# keeps useful boot/session logs while bounding disk pressure.
{ ... }:
{
  # Migrated from `services.journald.extraConfig` (a raw INI string) to
  # `services.journald.settings.Journal` after nixpkgs made extraConfig a
  # no-op assertion failure. Same effective config: 400 MiB cap instead of
  # the default 4 GiB / 15%-of-fs, which is too generous for our root
  # partitions.
  services.journald.settings.Journal.SystemMaxUse = "400M";
}
