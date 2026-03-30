# nix/home/git.nix
# Declarative git configuration

{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name  = "Nicolas Casatti";
      user.email = "ncasatti@gmail.com";
      core.editor = "nvim";
      credential.helper = "store";
    };
    signing.format = null;
  };
}
