{ inputs, ... }:

{
  additions = final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.system}.default;
    opencode = inputs.opencode-nix.packages.${prev.system}.default;
    clingy = inputs.clingy.packages.${prev.system}.default;
    antigravity-nix = inputs.antigravity-nix.packages.${prev.system}.default;
    engram = prev.callPackage ../packages/custom/engram.nix { };
    gemini-cli = prev.callPackage ../packages/custom/gemini-cli.nix { };
  };
}
