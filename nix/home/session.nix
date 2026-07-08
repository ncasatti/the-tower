# nix/home/session.nix
# Session-wide environment variables and PATH additions (declarative).
# Migrated out of fish conf.d/00-env + 01-path so they apply to every
# program, not just interactive fish.
#
# Dropped as dead during migration (directories no longer exist):
#   DOTNET_ROOT, JAVA_HOME, NVM_DIR, BAT_CONFIG_PATH, flutter/lmstudio/emacs
#   paths, /snap/bin, and TERM (the terminal sets TERM itself).
{ config, ... }:

{
  home.sessionVariables = {
    EDITOR      = "nvim";
    BROWSER     = "zen";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.bun/bin"
  ];
}
