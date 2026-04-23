{ inputs, ... }:

{
  additions = final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.system}.default;
    opencode = inputs.opencode-nix.packages.${prev.system}.default;
    clingy = inputs.clingy.packages.${prev.system}.default;
  };
}
