# nix/modules/journald.nix
# Limit systemd journal size. Default SystemMaxUse is 4 GiB or 15% of
# filesystem — too generous for our small root partitions. 400 MiB
# keeps useful boot/session logs while bounding disk pressure.
{ ... }:
{
  services.journald.extraConfig = ''
    SystemMaxUse=400M
  '';
}