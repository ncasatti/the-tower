{ inputs, ... }:

{
  additions = final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
    opencode = inputs.opencode-nix.packages.${prev.stdenv.hostPlatform.system}.default;
    clingy = inputs.clingy.packages.${prev.stdenv.hostPlatform.system}.default;
    antigravity-nix = inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.default;
    engram = prev.callPackage ../packages/custom/engram.nix { };
    gemini-cli = prev.callPackage ../packages/custom/gemini-cli.nix { };
  };
}
